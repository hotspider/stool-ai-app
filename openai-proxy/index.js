const express = require("express");
const cors = require("cors");

const app = express();
app.use(cors());
app.use(express.json({ limit: "25mb" }));

const DEFAULT_MODEL = process.env.OPENAI_MODEL || "gpt-4.1-mini";

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

必须输出的 JSON 结构如下：
{
  "ok": true,
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
  "reasoning_bullets": ["要点1","要点2","要点3"],
  "actions_today": {
    "diet": ["饮食建议"],
    "hydration": ["补液建议"],
    "care": ["护理建议"],
    "avoid": ["避免事项"]
  },
  "red_flags": [
    {"title":"何时需要就医/警戒","detail":"清晰阈值描述"}
  ],
  "follow_up_questions": ["可补充信息1","2"],
  "ui_strings": {
    "summary": "2-3句总结",
    "tags": ["Bristol 6","黄色","偏稀"],
    "sections": [
      {"title":"饮食","items":["..."]},
      {"title":"补液","items":["..."]},
      {"title":"护理","items":["..."]},
      {"title":"警戒信号","items":["..."]}
    ]
  },
  "summary": "同 ui_strings.summary",
  "bristol_type": null,
  "color": null,
  "texture": null,
  "hydration_hint": "从 actions_today.hydration 生成一句话",
  "diet_advice": ["同 actions_today.diet"]
}
`.trim();

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
    actions_today: {
      diet: [],
      hydration: [],
      care: [],
      avoid: [],
    },
    red_flags: [],
    follow_up_questions: [],
    ui_strings: {
      summary: "",
      tags: [],
      sections: [
        { title: "饮食", items: [] },
        { title: "补液", items: [] },
        { title: "护理", items: [] },
        { title: "警戒信号", items: [] },
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

function normalizeResult(parsed) {
  const base = buildDefaultResult();
  const out = { ...base, ...(parsed || {}) };

  const stool = { ...base.stool_features, ...(out.stool_features || {}) };
  const actions = { ...base.actions_today, ...(out.actions_today || {}) };
  const ui = { ...base.ui_strings, ...(out.ui_strings || {}) };

  out.ok = out.ok === false ? false : true;
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
    ? out.reasoning_bullets.map(String).slice(0, 5)
    : [];

  out.actions_today = {
    diet: Array.isArray(actions.diet) ? actions.diet.map(String) : [],
    hydration: Array.isArray(actions.hydration) ? actions.hydration.map(String) : [],
    care: Array.isArray(actions.care) ? actions.care.map(String) : [],
    avoid: Array.isArray(actions.avoid) ? actions.avoid.map(String) : [],
  };

  out.red_flags = Array.isArray(out.red_flags)
    ? out.red_flags.map((item) => {
        if (typeof item === "string") {
          return { title: item, detail: "" };
        }
        return {
          title: item?.title ? String(item.title) : "",
          detail: item?.detail ? String(item.detail) : "",
        };
      })
    : [];

  out.follow_up_questions = Array.isArray(out.follow_up_questions)
    ? out.follow_up_questions.map(String)
    : [];

  out.ui_strings = {
    summary: typeof ui.summary === "string" ? ui.summary : out.summary,
    tags: Array.isArray(ui.tags) ? ui.tags.map(String) : [],
    sections: Array.isArray(ui.sections)
      ? ui.sections.map((sec) => ({
          title: sec?.title ? String(sec.title) : "",
          items: Array.isArray(sec?.items) ? sec.items.map(String) : [],
        }))
      : base.ui_strings.sections,
  };

  out.summary = out.ui_strings.summary || out.summary || "";
  out.bristol_type = out.stool_features.bristol_type ?? null;
  out.color = out.stool_features.color ?? null;
  out.texture = out.stool_features.texture ?? null;
  out.hydration_hint = out.actions_today.hydration[0] || "";
  out.diet_advice = out.actions_today.diet || [];

  return out;
}

// ===== Endpoints =====
app.get("/ping", (_req, res) => res.json({ ok: true }));
app.get("/health", (_req, res) => res.json({ ok: true, ts: nowISO() }));
app.get("/version", (_req, res) =>
  res.json({ ok: true, version: process.env.RENDER_GIT_COMMIT || "unknown", ts: nowISO() })
);

app.post("/analyze", async (req, res) => {
  try {
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
      model: DEFAULT_MODEL,
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
      text: { format: { type: "json_object" } },
      temperature: 0.2,
      max_output_tokens: 1000
    };

    console.log(`[OPENAI] request model=${DEFAULT_MODEL} text.format=json_object`);
    const r = await fetch("https://api.openai.com/v1/responses", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${apiKey}`
      },
      body: JSON.stringify(payload)
    });
    console.log(`[OPENAI] response status=${r.status}`);

    const raw = await r.text().catch(() => "");
    if (!r.ok) {
      return res.status(502).json({ ok: false, error: "OPENAI_ERROR", message: raw || `OpenAI failed (${r.status})` });
    }

    const data = JSON.parse(raw);
    const outputText = extractOutputText(data);
    if (!outputText) {
      return res.status(502).json({ ok: false, error: "EMPTY_OUTPUT", message: "OpenAI response missing output text" });
    }

    let parsed;
    try {
      parsed = JSON.parse(outputText);
    } catch (e) {
      return res.status(502).json({ ok: false, error: "INVALID_JSON", message: "OpenAI returned non-JSON output" });
    }

    const normalized = normalizeResult(parsed);
    return res.json(normalized);
  } catch (err) {
    console.error("proxy /analyze error", err);
    return res.status(500).json({ ok: false, error: "PROXY_EXCEPTION", message: String(err?.message || err) });
  }
});

const port = process.env.PORT || 10000;
app.listen(port, () => console.log(`OpenAI proxy listening on port ${port}`));
