const express = require("express");
const cors = require("cors");

const app = express();
app.use(cors());
app.use(express.json({ limit: "25mb" }));

const PROXY_VERSION = process.env.RENDER_GIT_COMMIT || process.env.PROXY_VERSION || "dev";
const MODEL_ALLOWLIST = new Set(["gpt-5.2", "gpt-5d"]);

function normalizeModel(raw, fallback) {
  const model = (raw || "").trim();
  return MODEL_ALLOWLIST.has(model) ? model : fallback;
}

function getPrimaryModel() {
  return normalizeModel(process.env.OPENAI_MODEL_PRIMARY, "gpt-5.2");
}

function getFallbackModel() {
  return normalizeModel(process.env.OPENAI_MODEL_FALLBACK, "gpt-5d");
}

function pickModel(reqBody) {
  const reqModel =
    reqBody && typeof reqBody.model === "string" ? reqBody.model.trim() : "";
  if (MODEL_ALLOWLIST.has(reqModel)) {
    return reqModel;
  }
  return getPrimaryModel();
}

function shouldFallbackModel(rawText) {
  if (!rawText) return false;
  const text = rawText.toLowerCase();
  return (
    text.includes("model") &&
    (text.includes("not found") ||
      text.includes("does not exist") ||
      text.includes("not available") ||
      text.includes("not supported") ||
      text.includes("permission") ||
      text.includes("unauthorized") ||
      text.includes("invalid") ||
      text.includes("doesn't exist"))
  );
}

async function callOpenAI(apiKey, payload, primaryModel) {
  const fallbackModel = getFallbackModel();
  const tryOnce = async (model) => {
    const body = JSON.stringify({ ...payload, model });
    const r = await fetch("https://api.openai.com/v1/responses", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${apiKey}`,
      },
      body,
    });
    const raw = await r.text().catch(() => "");
    return { r, raw, model };
  };

  const first = await tryOnce(primaryModel);
  if (first.r.ok) {
    return first;
  }
  if (primaryModel !== fallbackModel && shouldFallbackModel(first.raw)) {
    return tryOnce(fallbackModel);
  }
  return first;
}

async function callOpenAIWithRetry(apiKey, basePayload, model) {
  const attemptPayloads = [
    basePayload,
    {
      ...basePayload,
      input: [
        {
          role: "system",
          content: [{ type: "input_text", text: STRICT_SYSTEM_PROMPT }],
        },
        ...basePayload.input.filter((c) => c.role !== "system"),
      ],
    },
  ];

  let last = null;
  for (let i = 0; i < attemptPayloads.length; i += 1) {
    const payload = attemptPayloads[i];
    const result = await callOpenAI(apiKey, payload, model);
    last = result;
    if (result.r.ok) {
      return result;
    }
  }
  return last;
}

// ===== Helpers =====
function nowISO() {
  return new Date().toISOString();
}

function extractOutputText(data) {
  // Responses API output_text 的兼容提取
  // 常见结构：data.output_text / data.output[0].content[0].text
  if (typeof data?.output_text === "string" && data.output_text.trim()) return data.output_text;

  const out = data?.output;
  if (Array.isArray(out)) {
    for (const item of out) {
      const content = item?.content;
      if (Array.isArray(content)) {
        for (const c of content) {
          if (c?.type === "output_text" && typeof c?.text === "string") return c.text;
          if (c?.type === "text" && typeof c?.text === "string") return c.text;
        }
      }
    }
  }
  return "";
}

function normalizeImageToDataUrl(image) {
  if (!image || typeof image !== "string") return "";
  const s = image.trim();
  if (!s) return "";
  if (s.startsWith("data:image/")) {
    return s;
  }
  const b64 = s.replace(/\s+/g, "");
  return `data:image/jpeg;base64,${b64}`;
}

const SYSTEM_PROMPT = `
你是儿科+营养师背景的健康助手。用户提供幼儿(0-36个月)大便图片与补充信息，你必须输出严格 JSON（不要 Markdown、不要额外文字）。
输出结构必须包含所有字段（允许 null/""/[] 但字段必须存在），且不要输出任何未列出的字段。
请尽量提供“家长可执行”的饮食/补液/护理/观察建议，并提供红旗预警。

You MUST output valid JSON object with schema_version=2 and the following fields:
headline (string),
score (0-100 int),
confidence (0-1 float),
uncertainty_note (string),
stool_features (object: bristol_type int|null, color string|null, texture string|null, visible_findings string[]),
reasoning_bullets (string[] length >= 5),
actions_today (string[] length >= 8, each is actionable and specific),
red_flags (string[] length >= 5, include pediatric red flags even if low risk),
follow_up_questions (string[] length >= 6),
ui_strings (object with sections: array of {title, icon_key, bullets[]} length >= 4).

Do NOT omit fields. If uncertain, fill with safe defaults and explain in uncertainty_note.
App 结果页“自然变厚”：每个 section 都有多条 bullet，不再像一句 summary。

必须输出的 JSON 结构如下：
{
  "ok": true,
  "schema_version": 2,
  "headline": "一句话结论",
  "score": 0-100,
  "risk_level": "low|medium|high",
  "confidence": 0.0-1.0,
  "uncertainty_note": "不确定说明",
  "stool_features": {
    "bristol_type": 1-7|null,
    "color": "string|null",
    "texture": "string|null",
    "volume": "small|medium|large|unknown",
    "visible_findings": ["mucus","undigested_food","blood","foam","watery","seeds","none"]
  },
  "reasoning_bullets": ["要点1","要点2","要点3","要点4","要点5"],
  "actions_today": ["具体行动1","2","3","4","5","6","7","8"],
  "red_flags": ["红旗1","2","3","4","5"],
  "follow_up_questions": ["问诊1","2","3","4","5","6"],
  "ui_strings": {
    "summary": "2-3句总结",
    "tags": ["Bristol 6","黄色","偏稀"],
    "sections": [
      {"title":"饮食","icon_key":"diet","bullets":["...","..."]},
      {"title":"补液","icon_key":"hydration","bullets":["...","..."]},
      {"title":"护理","icon_key":"care","bullets":["...","..."]},
      {"title":"警戒信号","icon_key":"warning","bullets":["...","..."]}
    ]
  },
  "summary": "同 ui_strings.summary",
  "bristol_type": null,
  "color": null,
  "texture": null,
  "hydration_hint": "从 actions_today 派生一句话",
  "diet_advice": ["从 actions_today 派生"]
}
`.trim();

const STRICT_SYSTEM_PROMPT = `
你必须输出严格 JSON（不要 Markdown、不要多余文字）。输出结构必须包含 schema_version=2 的全部字段，不允许任何额外字段。
如果不确定，请在 uncertainty_note 明确原因，但仍返回完整 JSON 对象。
`.trim();

const JSON_SCHEMA = {
  name: "stool_analysis_v2",
  schema: {
    type: "object",
    additionalProperties: false,
    properties: {
      ok: { type: "boolean" },
      schema_version: { type: "integer", enum: [2] },
      headline: { type: "string" },
      score: { type: "integer", minimum: 0, maximum: 100 },
      risk_level: { type: "string", enum: ["low", "medium", "high", "unknown"] },
      confidence: { type: "number", minimum: 0, maximum: 1 },
      uncertainty_note: { type: "string" },
      stool_features: {
        type: "object",
        additionalProperties: false,
        properties: {
          bristol_type: { type: ["integer", "null"], minimum: 1, maximum: 7 },
          color: { type: ["string", "null"] },
          texture: { type: ["string", "null"] },
          volume: { type: "string", enum: ["small", "medium", "large", "unknown"] },
          visible_findings: { type: "array", items: { type: "string" } },
        },
        required: ["bristol_type", "color", "texture", "volume", "visible_findings"],
      },
      reasoning_bullets: { type: "array", items: { type: "string" } },
      actions_today: { type: "array", items: { type: "string" } },
      red_flags: { type: "array", items: { type: "string" } },
      follow_up_questions: { type: "array", items: { type: "string" } },
      ui_strings: {
        type: "object",
        additionalProperties: false,
        properties: {
          summary: { type: "string" },
          tags: { type: "array", items: { type: "string" } },
          sections: {
            type: "array",
            items: {
              type: "object",
              additionalProperties: false,
              properties: {
                title: { type: "string" },
                icon_key: { type: "string" },
                items: { type: "array", items: { type: "string" } },
              },
              required: ["title", "icon_key", "items"],
            },
          },
        },
        required: ["summary", "tags", "sections"],
      },
      summary: { type: "string" },
      bristol_type: { type: ["integer", "null"], minimum: 1, maximum: 7 },
      color: { type: ["string", "null"] },
      texture: { type: ["string", "null"] },
      hydration_hint: { type: "string" },
      diet_advice: { type: "array", items: { type: "string" } },
    },
    required: [
      "ok",
      "schema_version",
      "headline",
      "score",
      "risk_level",
      "confidence",
      "uncertainty_note",
      "stool_features",
      "reasoning_bullets",
      "actions_today",
      "red_flags",
      "follow_up_questions",
      "ui_strings",
      "summary",
      "bristol_type",
      "color",
      "texture",
      "hydration_hint",
      "diet_advice",
    ],
  },
  strict: true,
};

function extractJsonFromText(text) {
  if (!text) return "";
  const candidates = [];
  for (let i = 0; i < text.length; i += 1) {
    if (text[i] !== "{") continue;
    let depth = 0;
    for (let j = i; j < text.length; j += 1) {
      if (text[j] === "{") depth += 1;
      if (text[j] === "}") depth -= 1;
      if (depth === 0) {
        candidates.push(text.slice(i, j + 1));
        break;
      }
    }
  }
  let best = "";
  for (const c of candidates) {
    try {
      JSON.parse(c);
      if (c.length > best.length) best = c;
    } catch {
      // ignore
    }
  }
  return best;
}

function sanitizeRawText(text) {
  if (!text) return "";
  let cleaned = text.trim();
  cleaned = cleaned.replace(/^```(?:json)?/i, "").replace(/```$/i, "");
  return cleaned.trim();
}

function buildModelOutputInvalid(usedModel, requestId) {
  return {
    ok: false,
    error_code: "MODEL_OUTPUT_INVALID",
    error: "MODEL_OUTPUT_INVALID",
    message: "Model returned non-JSON output",
    schema_version: 2,
    proxy_version: PROXY_VERSION,
    model_used: usedModel,
    headline: "模型输出异常，请重试",
    score: 0,
    risk_level: "unknown",
    confidence: 0,
    uncertainty_note: "模型输出未按 JSON 结构返回，可稍后重试或更换清晰图片。",
    stool_features: {
      bristol_type: null,
      color: null,
      texture: null,
      volume: "unknown",
      visible_findings: [],
    },
    reasoning_bullets: [],
    actions_today: [],
    red_flags: [],
    follow_up_questions: [],
    ui_strings: {
      summary: "",
      tags: [],
      sections: [
        {
          title: "重试建议",
          icon_key: "retry",
          items: ["稍后再试", "检查网络连接", "更换清晰图片"],
        },
        {
          title: "如何拍/如何裁剪",
          icon_key: "camera",
          items: ["光线充足", "对焦清晰", "目标占画面 50% 以上"],
        },
      ],
    },
    summary: "",
    bristol_type: null,
    color: null,
    texture: null,
    hydration_hint: "",
    diet_advice: [],
    openai_request_id: requestId || "",
  };
}

function userPromptFromBody(body) {
  const age = body?.age_months;
  const odor = body?.odor ?? "unknown";
  const strain = body?.pain_or_strain;
  const diet = body?.diet_keywords ?? "";
  return `
幼儿月龄: ${age ?? "unknown"}
气味: ${odor}
是否疼痛/费力: ${typeof strain === "boolean" ? String(strain) : "unknown"}
最近饮食关键词: ${diet || "unknown"}

请基于图片和以上信息给出分析与建议。
`.trim();
}

function buildDefaultResult() {
  return {
    ok: true,
    schema_version: 2,
    headline: "",
    score: 50,
    risk_level: "low",
    confidence: 0.6,
    uncertainty_note: "",
    stool_features: {
      bristol_type: null,
      color: null,
      texture: null,
      volume: "unknown",
      visible_findings: ["none"],
    },
    reasoning_bullets: [],
    actions_today: [],
    red_flags: [],
    follow_up_questions: [],
    ui_strings: {
      summary: "",
      tags: [],
      sections: [
        { title: "饮食", icon_key: "diet", items: [], bullets: [] },
        { title: "补液", icon_key: "hydration", items: [], bullets: [] },
        { title: "护理", icon_key: "care", items: [], bullets: [] },
        { title: "警戒信号", icon_key: "warning", items: [], bullets: [] },
      ],
    },
    summary: "",
    bristol_type: null,
    color: null,
    texture: null,
    hydration_hint: "",
    diet_advice: [],
  };
}

function ensureMinItems(list, min, defaults) {
  const base = Array.isArray(list) ? list.slice() : [];
  let i = 0;
  while (base.length < min) {
    base.push(defaults[i % defaults.length]);
    i += 1;
  }
  return base;
}

function normalizeResult(parsed) {
  const base = buildDefaultResult();
  const out = { ...base, ...(parsed || {}) };

  const stool = { ...base.stool_features, ...(out.stool_features || {}) };
  const ui = { ...base.ui_strings, ...(out.ui_strings || {}) };

  out.ok = out.ok === false ? false : true;
  out.schema_version = 2;
  out.model_used = typeof out.model_used === "string" ? out.model_used : undefined;
  out.proxy_version = typeof out.proxy_version === "string" ? out.proxy_version : PROXY_VERSION;
  out.score = Number.isFinite(Number(out.score)) ? Number(out.score) : base.score;
  out.risk_level = ["low", "medium", "high"].includes(out.risk_level)
    ? out.risk_level
    : base.risk_level;
  out.confidence = Number.isFinite(Number(out.confidence))
    ? Number(out.confidence)
    : base.confidence;
  out.uncertainty_note = typeof out.uncertainty_note === "string" ? out.uncertainty_note : "";
  out.headline = typeof out.headline === "string" ? out.headline : "";
  out.summary = typeof out.summary === "string" ? out.summary : "";

  out.stool_features = {
    bristol_type:
      stool.bristol_type === null
        ? null
        : Number.isFinite(Number(stool.bristol_type))
            ? Number(stool.bristol_type)
            : null,
    color: stool.color ?? null,
    texture: stool.texture ?? null,
    volume: ["small", "medium", "large", "unknown"].includes(stool.volume)
      ? stool.volume
      : "unknown",
    visible_findings: Array.isArray(stool.visible_findings)
      ? stool.visible_findings.map(String)
      : [],
  };

  out.reasoning_bullets = Array.isArray(out.reasoning_bullets)
    ? out.reasoning_bullets.map(String)
    : [];

  out.actions_today = Array.isArray(out.actions_today)
    ? out.actions_today.map(String)
    : [];

  out.red_flags = Array.isArray(out.red_flags) ? out.red_flags.map(String) : [];

  out.follow_up_questions = Array.isArray(out.follow_up_questions)
    ? out.follow_up_questions.map(String)
    : [];

  out.ui_strings = {
    summary: typeof ui.summary === "string" ? ui.summary : out.summary,
    tags: Array.isArray(ui.tags) ? ui.tags.map(String) : [],
    sections: Array.isArray(ui.sections)
      ? ui.sections.map((sec) => {
          const items = Array.isArray(sec?.items)
            ? sec.items
            : Array.isArray(sec?.bullets)
                ? sec.bullets
                : [];
          return {
            title: sec?.title ? String(sec.title) : "",
            icon_key: sec?.icon_key ? String(sec.icon_key) : "",
            items: Array.isArray(items) ? items.map(String) : [],
            bullets: Array.isArray(sec?.bullets)
              ? sec.bullets.map(String)
              : Array.isArray(sec?.items)
                  ? sec.items.map(String)
                  : [],
          };
        })
      : base.ui_strings.sections,
  };

  out.summary = out.ui_strings.summary || out.summary || "";
  out.bristol_type = out.stool_features.bristol_type ?? null;
  out.color = out.stool_features.color ?? null;
  out.texture = out.stool_features.texture ?? null;
  out.hydration_hint = out.actions_today[0] || "";
  out.diet_advice = out.actions_today.slice(0, 5);

  out.reasoning_bullets = ensureMinItems(out.reasoning_bullets, 5, [
    "根据颜色、质地与量的综合观察进行判断",
    "结合近期饮食与精神状态做辅助分析",
    "当前表现更像消化或饮食变化引起",
    "图片视角与光线会影响判断置信度",
    "建议继续记录 24-48 小时变化",
  ]);
  out.actions_today = ensureMinItems(out.actions_today, 8, [
    "少量多次补液，观察尿量",
    "今天饮食以清淡易消化为主",
    "避免油炸、辛辣和高糖食物",
    "适当补充含水分的水果/蔬菜",
    "记录排便次数与性状",
    "便后温水清洁并保持干爽",
    "观察是否伴随发热或呕吐",
    "如症状加重及时就医",
  ]);
  out.red_flags = ensureMinItems(out.red_flags, 5, [
    "明显便血或黑便",
    "持续高热或精神萎靡",
    "频繁呕吐或无法进食",
    "明显脱水（尿量明显减少/口干）",
    "腹痛剧烈或持续哭闹",
  ]);
  out.follow_up_questions = ensureMinItems(out.follow_up_questions, 6, [
    "是否发热？",
    "是否持续呕吐？",
    "24小时内排便次数多少？",
    "便血/黑便/灰白便是否出现？",
    "尿量是否减少？",
    "最近饮食有无明显变化？",
  ]);
  const sections = ensureMinItems(
    out.ui_strings.sections,
    4,
    base.ui_strings.sections
  ).map((sec, idx) => ({
    title: sec.title || base.ui_strings.sections[idx % 4].title,
    icon_key: sec.icon_key || base.ui_strings.sections[idx % 4].icon_key,
    items: ensureMinItems(
      sec.items || sec.bullets || [],
      2,
      out.actions_today.slice(0, 4)
    ),
    bullets: ensureMinItems(
      sec.bullets || sec.items || [],
      2,
      out.actions_today.slice(0, 4)
    ),
  }));

  const dietItems = out.actions_today.slice(0);
  const hydrationItems = out.actions_today.slice(0);
  const careItems = out.actions_today.slice(0);
  const warningItems = out.red_flags.map(String);
  const questionItems = out.follow_up_questions.slice(0);

  const hasDuplicateSections = sections.every((sec) => {
    const key = JSON.stringify(sec.items || []);
    return sections.every((s) => JSON.stringify(s.items || []) === key);
  });

  out.ui_strings.sections = hasDuplicateSections
    ? [
        { title: "饮食", icon_key: "diet", items: ensureMinItems(dietItems, 2, ["清淡饮食", "少量多餐"]) },
        {
          title: "补液",
          icon_key: "hydration",
          items: ensureMinItems(hydrationItems, 2, ["少量多次补液", "观察尿量"]),
        },
        { title: "护理", icon_key: "care", items: ensureMinItems(careItems, 2, ["便后清洁", "保持干爽"]) },
        {
          title: "警戒信号",
          icon_key: "warning",
          items: ensureMinItems(warningItems, 2, ["出现便血或黑便", "持续高热或明显不适"]),
        },
        {
          title: "追问问题",
          icon_key: "question",
          items: ensureMinItems(questionItems, 2, ["是否发热？", "24小时内排便次数多少？"]),
        },
      ]
    : sections;

  return out;
}

// ===== Endpoints =====
app.get("/ping", (_req, res) =>
  res.json({
    ok: true,
    proxy_version: PROXY_VERSION,
    schema_version: 2,
    model: getPrimaryModel(),
  })
);
app.get("/health", (_req, res) => res.json({ ok: true, ts: nowISO() }));
app.get("/version", (_req, res) =>
  res.json({ ok: true, version: process.env.RENDER_GIT_COMMIT || "unknown", ts: nowISO() })
);

app.post("/analyze", async (req, res) => {
  try {
    const model = pickModel(req.body);
    res.setHeader("x-proxy-version", PROXY_VERSION);
    res.setHeader("schema_version", "2");

    const apiKey = process.env.OPENAI_API_KEY;
    if (!apiKey) {
      return res.status(500).json({
        ok: false,
        error: "MISSING_API_KEY",
        message: "OPENAI_API_KEY is not set"
      });
    }

    const { image } = req.body || {};
    const imageDataUrl = normalizeImageToDataUrl(image);
    if (!imageDataUrl) {
      return res.status(400).json({
        ok: false,
        error: "NO_IMAGE",
        message: "image (base64 string) is required"
      });
    }

    const payload = {
      input: [
        {
          role: "system",
          content: [{ type: "input_text", text: SYSTEM_PROMPT }]
        },
        {
          role: "user",
          content: [
            { type: "input_text", text: userPromptFromBody(req.body) },
            { type: "input_image", image_url: imageDataUrl }
          ]
        }
      ],
      text: {
        format: {
          type: "json_schema",
          json_schema: JSON_SCHEMA,
        },
      },
      temperature: 0,
      max_output_tokens: 1000
    };

    console.log(`[OPENAI] request model=${model} text.format=json_schema`);
    const { r, raw, model: usedModel } = await callOpenAIWithRetry(
      apiKey,
      payload,
      model
    );
    console.log(`[OPENAI] response status=${r.status}`);

    res.setHeader("x-openai-model", usedModel);
    if (!r.ok) {
      return res.status(502).json({
        ok: false,
        error: "OPENAI_ERROR",
        message: raw || `OpenAI failed (${r.status})`,
        model_used: usedModel,
        schema_version: 2,
      });
    }

    const data = JSON.parse(raw);
    const outputText = extractOutputText(data);
    if (!outputText) {
      return res.status(502).json({
        ok: false,
        error: "EMPTY_OUTPUT",
        message: "OpenAI response missing output text",
        model_used: usedModel,
        schema_version: 2,
      });
    }

    let parsed;
    const cleanedText = sanitizeRawText(outputText);
    try {
      parsed = JSON.parse(cleanedText);
    } catch (e) {
      const extracted = extractJsonFromText(cleanedText);
      if (extracted) {
        try {
          parsed = JSON.parse(extracted);
        } catch {
          parsed = null;
        }
      }
      if (!parsed) {
        const requestId = r.headers.get("x-request-id") || "";
        const fallback = buildModelOutputInvalid(usedModel, requestId);
        fallback.raw_preview = String(cleanedText).slice(0, 500);
        return res.status(200).json(fallback);
      }
    }

    const normalized = normalizeResult(parsed);
    normalized.model_used = usedModel;
    res.setHeader("schema_version", String(normalized.schema_version || 2));
    return res.json(normalized);
  } catch (err) {
    console.error("proxy /analyze error", err);
    return res.status(500).json({ ok: false, error: "PROXY_EXCEPTION", message: String(err?.message || err) });
  }
});

const port = process.env.PORT || 10000;
app.listen(port, () => console.log(`OpenAI proxy listening on port ${port}`));
