const express = require("express");
const cors = require("cors");

const app = express();
app.use(cors());
app.use(express.json({ limit: "25mb" }));

const PROXY_VERSION = process.env.RENDER_GIT_COMMIT || process.env.PROXY_VERSION || "dev";
const BUILD_ID =
  process.env.BUILD_ID ||
  (process.env.RENDER_GIT_COMMIT
    ? process.env.RENDER_GIT_COMMIT.slice(0, 7)
    : process.env.PROXY_VERSION
      ? process.env.PROXY_VERSION.slice(0, 7)
      : "unknown");
app.use((req, res, next) => {
  res.setHeader("x-build-id", BUILD_ID);
  next();
});
const { V2_SCHEMA_JSON } = require("./src/schema/v2_schema");
const { isStoolImageGuard } = require("./src/analyze/guard/is_stool_image");
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
  const primaryModel = model;
  const fallbackModel = getFallbackModel();
  const attemptPayloads = [
    basePayload,
    {
      ...basePayload,
      temperature: 0,
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
    const result = await callOpenAI(apiKey, payload, primaryModel);
    last = result;
    if (result.r.ok) {
      return result;
    }
  }

  if (fallbackModel !== primaryModel) {
    const fallbackPayload = {
      ...basePayload,
      temperature: 0,
      input: [
        {
          role: "system",
          content: [{ type: "input_text", text: STRICT_SYSTEM_PROMPT }],
        },
        ...basePayload.input.filter((c) => c.role !== "system"),
      ],
    };
    return callOpenAI(apiKey, fallbackPayload, fallbackModel);
  }
  return last;
}

function buildStrictPayload(basePayload) {
  return {
    ...basePayload,
    temperature: 0,
    input: [
      {
        role: "system",
        content: [{ type: "input_text", text: STRICT_SYSTEM_PROMPT }],
      },
      ...basePayload.input.filter((c) => c.role !== "system"),
    ],
  };
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
输出结构必须包含所有字段，且不要输出任何未列出的字段。请提供“家长可执行”的饮食/补液/护理/观察建议，并提供红旗预警。

写作结构强约束：
1. 必须先输出“一句话结论（先说重点）”（写进 headline / ui_strings.longform.conclusion），明确：是否像腹泻/是否像感染/更像什么。
2. “具体怎么看这个便便”必须分为：形态/颜色/质地细节，并且每部分都要写“为什么会这样”（写进 interpretation.why_*，每项>=2）。
3. 必须输出“结合你填写的情况（很关键）”，并引用 context（foods_eaten, drinks_taken, mood_state, other_notes），写入 interpretation.how_context_affects（>=3）。
4. “可能原因”必须按常见程度排序（写入 possible_causes 与 reasoning_bullets，possible_causes>=3，reasoning_bullets>=5）。
5. “现在需要做什么”必须可执行，分 ✅可以做 / ❌少一点 / 👀观察指标（分别落在 actions_today.*）。
6. “什么时候需要警惕”必须给明确红旗（red_flags >=5，object 结构 {title, detail}）。
7. 最后输出“家长安心指标”一句话总结（写入 ui_strings.longform.reassure）。
8. 语言风格：像儿科医生对家长说话，清晰克制、不吓人；禁止空话；禁止只输出泛泛建议。
9. 必须填满 required 数组长度下限，任何数组不允许为空，避免使用 "unknown" 或 “信息不足” 作为主结论文本。
10. 若图片无法判断，必须明确写出“缺什么信息/建议怎么拍/建议补充什么”，并仍返回完整 v2 结构（ok=false，但字段齐全）。

你会收到两类信息：
1) image（图片内容：可能是大便，也可能不是）
2) context（用户补充信息，可为空）：foods_eaten, drinks_taken, mood_state, other_notes

强制要求：
- 必须读取并使用 context（如果 context 为空，要在 context_summary 中明确写“未提供补充信息，因此只按图片判断”）。
- 输出中必须包含：
  - context_summary：用一段话概括用户补充信息，并解释它如何影响判断（或为何无法影响）。
  - analysis_basis.image_only：仅基于图片可观察到的依据（>=4条）
  - analysis_basis.combined_reasoning：结合图片 + context 的推理链（>=5条）
  - input_echo.context：原样回显 context（便于前端验收）
- 若 context 中包含饮食/饮水/精神状态/其他症状，请在 reasoning_bullets 和 actions_today 中体现“因这些信息而调整的判断/建议”。

二阶段分析输出模板（必须体现为字段内容）：
1) 一句话结论（先说重点）：写入 doctor_explanation.one_sentence_conclusion 与 headline。
2) 具体怎么看这个便便：写入 doctor_explanation.shape / color / texture，并同步写入 doctor_explanation.visual_analysis.*。
3) 结合宝宝情况：写入 interpretation.how_context_affects。
4) 可能原因：写入 possible_causes（Top3）+ reasoning_bullets。
5) 现在需要做什么：actions_today（✅/❌/👀）。
6) 家长安心指标：写入 ui_strings.longform.reassure。

必须输出 JSON 并严格匹配 schema_version=2 的结构，字段如下（仅列要点）：
- ok, schema_version=2, is_stool_image=true, headline, score, risk_level, confidence, uncertainty_note
- stool_features: shape, shape_desc, color, color_desc, color_reason, texture, texture_desc, abnormal_signs, bristol_type, bristol_range, volume, wateriness, mucus, foam, blood, undigested_food, separation_layers, odor_level, visible_findings
- doctor_explanation: one_sentence_conclusion, shape, color, texture, visual_analysis{shape,color,texture}, combined_judgement
- possible_causes: [{title, explanation}]
- interpretation: overall_judgement, why_shape[], why_color[], why_texture[], how_context_affects[], confidence_explain
- reasoning_bullets[], actions_today{diet,hydration,care,avoid,observe}, red_flags[{title,detail}], follow_up_questions[]
- ui_strings{summary,tags,sections, longform{conclusion,how_to_read,context,causes,todo,red_flags,reassure}}
- context_summary, analysis_basis{image_only, combined_reasoning}, input_echo{context}
- model_used, proxy_version, worker_version?, context_input?

只输出 JSON，不要 Markdown。
`.trim();

const STRICT_SYSTEM_PROMPT = `
你必须输出严格 JSON（不要 Markdown、不要多余文字）。输出结构必须包含 schema_version=2 的全部字段，不允许任何额外字段。
只输出一个 JSON，不要任何解释/markdown/代码块。若不确定，请在 uncertainty_note 明确原因，但仍返回完整 JSON 对象。
`.trim();

const JSON_SCHEMA = {
  name: "stool_analysis_v2",
  strict: true,
  schema: V2_SCHEMA_JSON,
};

function extractJsonFromText(text) {
  if (!text) return "";
  const start = text.indexOf("{");
  if (start === -1) return "";
  let depth = 0;
  for (let i = start; i < text.length; i += 1) {
    if (text[i] === "{") depth += 1;
    if (text[i] === "}") depth -= 1;
    if (depth === 0) {
      const candidate = text.slice(start, i + 1);
      try {
        JSON.parse(candidate);
        return candidate;
      } catch {
        return "";
      }
    }
  }
  return "";
}

function sanitizeRawText(text) {
  if (!text) return "";
  let cleaned = text.trim();
  cleaned = cleaned.replace(/```(?:json)?/gi, "");
  return cleaned.trim();
}

function buildModelOutputInvalid(usedModel, requestId) {
  const base = buildDefaultResult();
  return {
    ...base,
    ok: false,
    error_code: "PROXY_ERROR",
    error: "PROXY_ERROR",
    message: "Model returned non-JSON output",
    schema_version: 2,
    proxy_version: PROXY_VERSION,
    model_used: usedModel || base.model_used,
    headline: "服务暂不可用，请稍后重试",
    score: 0,
    risk_level: "unknown",
    confidence: 0,
    uncertainty_note: "服务繁忙或网络异常，可稍后重试或更换清晰图片。",
    ui_strings: {
      ...base.ui_strings,
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
        {
          title: "需要补充的信息",
          icon_key: "question",
          items: ["是否发热/呕吐", "24h 排便次数", "近期饮食与饮水"],
        },
        {
          title: "观察指标",
          icon_key: "observe",
          items: ["精神与食欲", "尿量", "便次数与性状变化"],
        },
      ],
    },
    openai_request_id: requestId || "",
  };
}

function buildErrorResult(errorCode, message, usedModel) {
  const base = buildDefaultResult();
  return {
    ...base,
    ok: false,
    error_code: errorCode,
    error: errorCode,
    message: message || "Request failed",
    schema_version: 2,
    proxy_version: PROXY_VERSION,
    model_used: usedModel || base.model_used,
    headline: "暂时无法完成分析",
    score: 0,
    risk_level: "unknown",
    confidence: 0,
    uncertainty_note: message || "当前请求未成功处理。",
  };
}

function userPromptFromBody(body) {
  const age = body?.age_months;
  const odor = body?.odor ?? "unknown";
  const strain = body?.pain_or_strain;
  const diet = body?.diet_keywords ?? "";
  const context = body?.context ?? body?.context_input ?? {};
  return `
幼儿月龄: ${age ?? "unknown"}
气味: ${odor}
是否疼痛/费力: ${typeof strain === "boolean" ? String(strain) : "unknown"}
最近饮食关键词: ${diet || "unknown"}
补充信息(context): ${JSON.stringify(context)}

请基于图片和以上信息给出分析与建议。
`.trim();
}

function buildDefaultResult() {
  return {
    ok: true,
    schema_version: 2,
    is_stool_image: true,
    headline: "",
    score: 50,
    risk_level: "low",
    confidence: 0.6,
    uncertainty_note: "",
    stool_features: {
      bristol_type: null,
      bristol_range: "unknown",
      shape: "偏软/糊状",
      shape_desc: "unknown",
      color: "黄褐/偏黄",
      color_desc: "unknown",
      color_reason: "多与饮食构成和肠道通过速度相关",
      texture: "细腻/糊状",
      texture_desc: "unknown",
      abnormal_signs: ["未见明显异常"],
      volume: "unknown",
      wateriness: "none",
      mucus: "none",
      foam: "none",
      blood: "none",
      undigested_food: "none",
      separation_layers: "none",
      odor_level: "unknown",
      visible_findings: ["none"],
    },
    doctor_explanation: {
      one_sentence_conclusion: "",
      shape: "",
      color: "",
      texture: "",
      visual_analysis: { shape: "", color: "", texture: "" },
      combined_judgement: "",
    },
    possible_causes: [],
    interpretation: {
      overall_judgement: "需要结合更多信息判断",
      why_shape: ["图片角度与光线影响形态判断", "仅凭单张图片可能低估真实形态"],
      why_color: ["颜色受光照与拍摄设备影响", "需结合近期饮食判断颜色变化"],
      why_texture: ["质地可能受水分与拍摄焦距影响", "需结合是否拉稀或成形判断"],
      how_context_affects: ["未提供补充信息，无法判断饮食与症状关联", "若近期有发热/腹痛需提高警惕", "若精神食欲正常则更偏功能性变化"],
      confidence_explain: "缺少完整补充信息，置信度有限。",
    },
    context_summary: "未提供补充信息，仅基于图片判断。",
    analysis_basis: {
      image_only: [
        "图片中可见的形态与质地特征",
        "颜色分布与光照条件下的表现",
        "是否可见明显异物/血丝/粘液",
        "整体成形度与水样分离情况",
      ],
      combined_reasoning: [
        "图片特征与补充信息综合后更偏向功能性变化",
        "饮食与饮水情况可能影响颜色与质地",
        "精神状态与症状有助判断是否存在感染迹象",
        "如无发热/呕吐更支持可观察的短期变化",
        "若补充信息不足需保留不确定性",
      ],
    },
    input_echo: {
      context: {},
    },
    reasoning_bullets: [],
    actions_today: {
      diet: [],
      hydration: [],
      care: [],
      avoid: [],
      observe: [],
    },
    red_flags: [],
    follow_up_questions: [],
    ui_strings: {
      summary: "",
      tags: [],
      sections: [
        { title: "饮食", icon_key: "diet", items: [] },
        { title: "补液", icon_key: "hydration", items: [] },
        { title: "护理", icon_key: "care", items: [] },
        { title: "警戒信号", icon_key: "warning", items: [] },
      ],
      longform: {
        conclusion: "",
        how_to_read: "",
        context: "",
        causes: "",
        todo: "",
        red_flags: "",
        reassure: "",
      },
    },
    model_used: "unknown",
    proxy_version: PROXY_VERSION,
    explanation: "",
  };
}

function buildNotStoolResult(guard) {
  const base = buildDefaultResult();
  return {
    ...base,
    ok: false,
    is_stool_image: false,
    error_code: "NOT_STOOL_IMAGE",
    error: "NOT_STOOL_IMAGE",
    headline: "这张图片未识别到大便，暂时无法分析",
    risk_level: "unknown",
    confidence: Number.isFinite(Number(guard?.confidence)) ? Number(guard.confidence) : 0,
    explanation: guard?.reason || "未识别到大便图像。",
    stool_features: null,
    doctor_explanation: null,
    ui_strings: {
      ...base.ui_strings,
      sections: [
        {
          title: "无法分析的原因",
          icon_key: "camera",
          items: [
            "图片中未识别到大便",
            "可能拍到了其他物体或场景",
            "建议只拍大便本身",
          ],
        },
        {
          title: "请重新拍摄",
          icon_key: "retry",
          items: [
            "光线充足，避免背光/强反光",
            "对焦清晰，大便占画面 50% 以上",
            "尽量减少背景干扰",
          ],
        },
      ],
    },
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
  const doctor = { ...base.doctor_explanation, ...(out.doctor_explanation || {}) };
  const causes = Array.isArray(out.possible_causes) ? out.possible_causes : [];
  const interpretation = { ...base.interpretation, ...(out.interpretation || {}) };
  const actions = { ...base.actions_today, ...(out.actions_today || {}) };
  const ui = { ...base.ui_strings, ...(out.ui_strings || {}) };
  const longform = { ...base.ui_strings.longform, ...(ui.longform || {}) };

  out.ok = out.ok === false ? false : true;
  out.schema_version = 2;
  out.is_stool_image = out.is_stool_image === false ? false : true;
  out.model_used = typeof out.model_used === "string" && out.model_used.trim()
    ? out.model_used.trim()
    : base.model_used;
  out.proxy_version = typeof out.proxy_version === "string" && out.proxy_version.trim()
    ? out.proxy_version.trim()
    : PROXY_VERSION;
  out.worker_version = typeof out.worker_version === "string" ? out.worker_version : out.worker_version;
  out.context_input = typeof out.context_input === "object" && out.context_input
    ? out.context_input
    : undefined;
  out.input_context = typeof out.input_context === "object" && out.input_context
    ? out.input_context
    : undefined;
  out.context_summary = typeof out.context_summary === "string" && out.context_summary.trim()
    ? out.context_summary.trim()
    : base.context_summary;
  const basis = { ...base.analysis_basis, ...(out.analysis_basis || {}) };
  out.analysis_basis = {
    image_only: ensureMinItems(
      Array.isArray(basis.image_only) ? basis.image_only.map(String) : [],
      4,
      base.analysis_basis.image_only
    ),
    combined_reasoning: ensureMinItems(
      Array.isArray(basis.combined_reasoning) ? basis.combined_reasoning.map(String) : [],
      5,
      base.analysis_basis.combined_reasoning
    ),
  };
  const echo = out.input_echo && typeof out.input_echo === "object" ? out.input_echo : base.input_echo;
  out.input_echo = {
    context: echo && typeof echo.context === "object" ? echo.context : {},
  };
  out.score = Number.isFinite(Number(out.score)) ? Number(out.score) : base.score;
  out.risk_level = ["low", "medium", "high"].includes(out.risk_level)
    ? out.risk_level
    : base.risk_level;
  if (out.is_stool_image === false) {
    out.risk_level = "unknown";
  }
  out.confidence = Number.isFinite(Number(out.confidence))
    ? Number(out.confidence)
    : base.confidence;
  out.uncertainty_note = typeof out.uncertainty_note === "string" ? out.uncertainty_note : "";
  out.headline = typeof out.headline === "string" ? out.headline : "";
  out.explanation = typeof out.explanation === "string" ? out.explanation : "";

  out.stool_features = out.is_stool_image === false
    ? null
    : {
    shape:
      typeof stool.shape === "string" && stool.shape.trim()
        ? stool.shape.trim()
        : base.stool_features.shape,
    bristol_type:
      stool.bristol_type === null
        ? null
        : Number.isFinite(Number(stool.bristol_type))
            ? Number(stool.bristol_type)
            : null,
    bristol_range:
      typeof stool.bristol_range === "string" && stool.bristol_range.trim()
        ? stool.bristol_range.trim()
        : base.stool_features.bristol_range,
    shape_desc:
      typeof stool.shape_desc === "string" && stool.shape_desc.trim()
        ? stool.shape_desc.trim()
        : base.stool_features.shape_desc,
    color:
      typeof stool.color === "string" && stool.color.trim()
        ? stool.color.trim()
        : base.stool_features.color,
    color_desc:
      typeof stool.color_desc === "string" && stool.color_desc.trim()
        ? stool.color_desc.trim()
        : base.stool_features.color_desc,
    color_reason:
      typeof stool.color_reason === "string" && stool.color_reason.trim()
        ? stool.color_reason.trim()
        : base.stool_features.color_reason,
    texture:
      typeof stool.texture === "string" && stool.texture.trim()
        ? stool.texture.trim()
        : base.stool_features.texture,
    texture_desc:
      typeof stool.texture_desc === "string" && stool.texture_desc.trim()
        ? stool.texture_desc.trim()
        : base.stool_features.texture_desc,
    abnormal_signs: Array.isArray(stool.abnormal_signs)
      ? stool.abnormal_signs.map(String)
      : [],
    volume: ["small", "medium", "large", "unknown"].includes(stool.volume)
      ? stool.volume
      : "unknown",
    wateriness: ["none", "mild", "moderate", "severe"].includes(stool.wateriness)
      ? stool.wateriness
      : "none",
    mucus: ["none", "suspected", "present"].includes(stool.mucus) ? stool.mucus : "none",
    foam: ["none", "suspected", "present"].includes(stool.foam) ? stool.foam : "none",
    blood: ["none", "suspected", "present"].includes(stool.blood) ? stool.blood : "none",
    undigested_food: ["none", "suspected", "present"].includes(stool.undigested_food)
      ? stool.undigested_food
      : "none",
    separation_layers: ["none", "suspected", "present"].includes(stool.separation_layers)
      ? stool.separation_layers
      : "none",
    odor_level: ["normal", "strong", "very_strong", "unknown"].includes(stool.odor_level)
      ? stool.odor_level
      : "unknown",
    visible_findings: Array.isArray(stool.visible_findings)
      ? stool.visible_findings.map(String)
      : [],
  };

  if (out.stool_features) {
    out.stool_features.visible_findings = ensureMinItems(
      out.stool_features.visible_findings,
      1,
      ["none"]
    );
    out.stool_features.abnormal_signs = ensureMinItems(
      out.stool_features.abnormal_signs,
      1,
      ["未见明显异常"]
    );
  }

  out.doctor_explanation = out.is_stool_image === false
    ? null
    : {
        one_sentence_conclusion:
          typeof doctor.one_sentence_conclusion === "string" && doctor.one_sentence_conclusion.trim()
            ? doctor.one_sentence_conclusion.trim()
            : out.headline || base.doctor_explanation.one_sentence_conclusion,
        shape:
          typeof doctor.shape === "string" && doctor.shape.trim()
            ? doctor.shape.trim()
            : "",
        color:
          typeof doctor.color === "string" && doctor.color.trim()
            ? doctor.color.trim()
            : "",
        texture:
          typeof doctor.texture === "string" && doctor.texture.trim()
            ? doctor.texture.trim()
            : "",
        visual_analysis: {
          shape:
            typeof doctor.visual_analysis?.shape === "string" && doctor.visual_analysis.shape.trim()
              ? doctor.visual_analysis.shape.trim()
              : "",
          color:
            typeof doctor.visual_analysis?.color === "string" && doctor.visual_analysis.color.trim()
              ? doctor.visual_analysis.color.trim()
              : "",
          texture:
            typeof doctor.visual_analysis?.texture === "string" && doctor.visual_analysis.texture.trim()
              ? doctor.visual_analysis.texture.trim()
              : "",
        },
        combined_judgement:
          typeof doctor.combined_judgement === "string" && doctor.combined_judgement.trim()
            ? doctor.combined_judgement.trim()
            : interpretation.overall_judgement || base.interpretation.overall_judgement,
      };

  if (out.doctor_explanation) {
    if (!out.doctor_explanation.shape && out.doctor_explanation.visual_analysis?.shape) {
      out.doctor_explanation.shape = out.doctor_explanation.visual_analysis.shape;
    }
    if (!out.doctor_explanation.color && out.doctor_explanation.visual_analysis?.color) {
      out.doctor_explanation.color = out.doctor_explanation.visual_analysis.color;
    }
    if (!out.doctor_explanation.texture && out.doctor_explanation.visual_analysis?.texture) {
      out.doctor_explanation.texture = out.doctor_explanation.visual_analysis.texture;
    }
  }

  out.possible_causes = ensureMinItems(
    causes.map((item) => {
      if (!item || typeof item !== "object") {
        return { title: "饮食结构影响", explanation: "近期饮食变化会让便便更偏软。"};
      }
      return {
        title: item.title ? String(item.title) : "常见原因",
        explanation: item.explanation ? String(item.explanation) : "常见原因导致的短期变化。",
      };
    }),
    3,
    [
      { title: "饮食结构影响", explanation: "水果或含水量高的食物增加会让便便偏软。" },
      { title: "肠道蠕动偏快", explanation: "幼儿阶段肠道功能调试期，容易偏软。" },
      { title: "轻微受凉或作息变化", explanation: "环境变化可短暂影响消化节律。" },
    ]
  );

  out.interpretation = {
    overall_judgement:
      typeof interpretation.overall_judgement === "string" && interpretation.overall_judgement.trim()
        ? interpretation.overall_judgement.trim()
        : base.interpretation.overall_judgement,
    why_shape: Array.isArray(interpretation.why_shape) ? interpretation.why_shape.map(String) : [],
    why_color: Array.isArray(interpretation.why_color) ? interpretation.why_color.map(String) : [],
    why_texture: Array.isArray(interpretation.why_texture) ? interpretation.why_texture.map(String) : [],
    how_context_affects: Array.isArray(interpretation.how_context_affects)
      ? interpretation.how_context_affects.map(String)
      : [],
    confidence_explain:
      typeof interpretation.confidence_explain === "string" && interpretation.confidence_explain.trim()
        ? interpretation.confidence_explain.trim()
        : base.interpretation.confidence_explain,
  };

  out.reasoning_bullets = Array.isArray(out.reasoning_bullets)
    ? out.reasoning_bullets.map(String)
    : [];

  out.actions_today = {
    diet: Array.isArray(actions.diet) ? actions.diet.map(String) : [],
    hydration: Array.isArray(actions.hydration) ? actions.hydration.map(String) : [],
    care: Array.isArray(actions.care) ? actions.care.map(String) : [],
    avoid: Array.isArray(actions.avoid) ? actions.avoid.map(String) : [],
    observe: Array.isArray(actions.observe) ? actions.observe.map(String) : [],
  };

  out.red_flags = Array.isArray(out.red_flags) ? out.red_flags : [];
  out.red_flags = out.red_flags.map((item) => {
    if (item && typeof item === "object") {
      return {
        title: item.title ? String(item.title) : "需要警惕的情况",
        detail: item.detail ? String(item.detail) : "如出现请及时就医或咨询医生。",
      };
    }
    const text = String(item || "");
    return { title: text || "需要警惕的情况", detail: "如出现请及时就医或咨询医生。" };
  });

  out.follow_up_questions = Array.isArray(out.follow_up_questions)
    ? out.follow_up_questions.map(String)
    : [];

  out.ui_strings = {
    summary: typeof ui.summary === "string" ? ui.summary : "",
    tags: Array.isArray(ui.tags) ? ui.tags.map(String) : [],
    sections: Array.isArray(ui.sections)
      ? ui.sections.map((sec) => {
          return {
            title: sec?.title ? String(sec.title) : "",
            icon_key: sec?.icon_key ? String(sec.icon_key) : "info",
            items: Array.isArray(sec?.items) ? sec.items.map(String) : [],
          };
        })
      : base.ui_strings.sections,
    longform: {
      conclusion:
        typeof longform.conclusion === "string" && longform.conclusion.trim()
          ? longform.conclusion.trim()
          : "",
      how_to_read:
        typeof longform.how_to_read === "string" && longform.how_to_read.trim()
          ? longform.how_to_read.trim()
          : "",
      context:
        typeof longform.context === "string" && longform.context.trim()
          ? longform.context.trim()
          : "",
      causes:
        typeof longform.causes === "string" && longform.causes.trim()
          ? longform.causes.trim()
          : "",
      todo:
        typeof longform.todo === "string" && longform.todo.trim()
          ? longform.todo.trim()
          : "",
      red_flags:
        typeof longform.red_flags === "string" && longform.red_flags.trim()
          ? longform.red_flags.trim()
          : "",
      reassure:
        typeof longform.reassure === "string" && longform.reassure.trim()
          ? longform.reassure.trim()
          : "",
    },
  };

  out.reasoning_bullets = ensureMinItems(out.reasoning_bullets, 5, [
    "根据颜色、质地与量的综合观察进行判断",
    "结合近期饮食与精神状态做辅助分析",
    "当前表现更像消化或饮食变化引起",
    "图片视角与光线会影响判断置信度",
    "建议继续记录 24-48 小时变化",
  ]);

  out.actions_today.diet = ensureMinItems(out.actions_today.diet, 3, [
    "饮食清淡易消化，少量多餐",
    "适当增加软熟主食与蔬果",
    "观察是否对乳制品更敏感",
  ]);
  out.actions_today.hydration = ensureMinItems(out.actions_today.hydration, 3, [
    "少量多次补液",
    "观察尿量和尿色",
    "可用口服补液盐按说明补充",
  ]);
  out.actions_today.care = ensureMinItems(out.actions_today.care, 3, [
    "便后温水清洁并保持干爽",
    "记录排便次数与形态变化",
    "保持充足睡眠与作息",
  ]);
  out.actions_today.avoid = ensureMinItems(out.actions_today.avoid, 3, [
    "避免油炸辛辣和高糖食物",
    "减少冰冷饮品",
    "避免一次性大量进食",
  ]);
  out.actions_today.observe = ensureMinItems(out.actions_today.observe, 3, [
    "精神与食欲是否下降",
    "排便次数是否明显增多",
    "是否出现发热或呕吐",
  ]);

  out.red_flags = ensureMinItems(out.red_flags, 5, [
    { title: "明显便血或黑便", detail: "若出现，尽快就医评估。" },
    { title: "持续高热或精神萎靡", detail: "精神差或高热不退需就医。" },
    { title: "频繁呕吐或无法进食", detail: "影响进食与补液要及时处理。" },
    { title: "明显脱水表现", detail: "尿量明显减少、口干或皮肤干燥。" },
    { title: "腹痛剧烈或持续哭闹", detail: "需要医生评估腹痛原因。" },
  ]);
  out.follow_up_questions = ensureMinItems(out.follow_up_questions, 6, [
    "是否发热？",
    "是否持续呕吐？",
    "24小时内排便次数多少？",
    "便血/黑便/灰白便是否出现？",
    "尿量是否减少？",
    "最近饮食有无明显变化？",
  ]);

  const sections = ensureMinItems(out.ui_strings.sections, 4, base.ui_strings.sections).map(
    (sec, idx) => ({
      title: sec.title || base.ui_strings.sections[idx % 4].title,
      icon_key: sec.icon_key || base.ui_strings.sections[idx % 4].icon_key,
      items: ensureMinItems(
        sec.items || [],
        3,
        out.actions_today.diet.slice(0, 3)
      ),
    })
  );

  const dietItems = out.actions_today.diet.slice(0);
  const hydrationItems = out.actions_today.hydration.slice(0);
  const careItems = out.actions_today.care.slice(0);
  const warningItems = out.red_flags.map((f) => `${f.title}: ${f.detail}`);
  const questionItems = out.follow_up_questions.slice(0);
  const observeItems = out.actions_today.observe.slice(0);

  const hasDuplicateSections = sections.every((sec) => {
    const key = JSON.stringify(sec.items || []);
    return sections.every((s) => JSON.stringify(s.items || []) === key);
  });

  out.ui_strings.sections = hasDuplicateSections
    ? [
        { title: "饮食", icon_key: "diet", items: ensureMinItems(dietItems, 3, ["清淡饮食", "少量多餐", "避免油腻"]) },
        {
          title: "补液",
          icon_key: "hydration",
          items: ensureMinItems(hydrationItems, 3, ["少量多次补液", "观察尿量", "必要时口服补液盐"]),
        },
        { title: "护理", icon_key: "care", items: ensureMinItems(careItems, 3, ["便后清洁", "保持干爽", "记录变化"]) },
        {
          title: "警戒信号",
          icon_key: "warning",
          items: ensureMinItems(warningItems, 3, ["出现便血或黑便", "持续高热或明显不适", "频繁呕吐"]) },
        {
          title: "观察指标",
          icon_key: "observe",
          items: ensureMinItems(observeItems, 3, ["精神与食欲", "排便次数", "是否发热"]) },
        {
          title: "追问问题",
          icon_key: "question",
          items: ensureMinItems(questionItems, 3, ["是否发热？", "24小时内排便次数多少？", "是否呕吐？"]) },
      ]
    : sections;

  out.interpretation.why_shape = ensureMinItems(out.interpretation.why_shape, 2, base.interpretation.why_shape);
  out.interpretation.why_color = ensureMinItems(out.interpretation.why_color, 2, base.interpretation.why_color);
  out.interpretation.why_texture = ensureMinItems(out.interpretation.why_texture, 2, base.interpretation.why_texture);
  out.interpretation.how_context_affects = ensureMinItems(
    out.interpretation.how_context_affects,
    3,
    base.interpretation.how_context_affects
  );

  out.ui_strings.longform = {
    conclusion: out.ui_strings.longform.conclusion || out.headline || "整体情况需要继续观察。",
    how_to_read:
      out.ui_strings.longform.how_to_read ||
      out.stool_features
        ? `形态：${out.stool_features.shape_desc}；颜色：${out.stool_features.color_desc}；质地：${out.stool_features.texture_desc}。`
        : "图片无法识别为大便，建议重新拍摄。",
    context:
      out.ui_strings.longform.context ||
      out.interpretation.how_context_affects.join("；"),
    causes:
      out.ui_strings.longform.causes || out.reasoning_bullets.slice(0, 3).join("；"),
    todo:
      out.ui_strings.longform.todo ||
      `✅可以做：${out.actions_today.diet.slice(0, 2).join("；")}；❌少一点：${out.actions_today.avoid.slice(0, 2).join("；")}；👀观察：${out.actions_today.observe.slice(0, 2).join("；")}`,
    red_flags:
      out.ui_strings.longform.red_flags ||
      out.red_flags.slice(0, 2).map((f) => `${f.title}（${f.detail}）`).join("；"),
    reassure:
      out.ui_strings.longform.reassure ||
      "若精神和食欲良好、尿量正常，通常可先在家观察并记录变化。",
  };

  out.bristol_type = out.stool_features?.bristol_type ?? null;
  out.color = out.stool_features?.color_desc ?? null;
  out.texture = out.stool_features?.texture_desc ?? null;
  out.hydration_hint = out.actions_today.hydration[0] || "";
  out.diet_advice = out.actions_today.diet.slice(0, 5);

  return out;
}

// ===== Endpoints =====
app.get("/ping", (_req, res) =>
  res.json({
    ok: true,
    proxy_version: PROXY_VERSION,
    schema_version: 2,
    model: getPrimaryModel(),
    build_id: BUILD_ID,
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
    res.setHeader("x-openai-model", model);

    const apiKey = process.env.OPENAI_API_KEY;
    if (!apiKey) {
      const errResult = normalizeResult(
        buildErrorResult("MISSING_API_KEY", "OPENAI_API_KEY is not set", model)
      );
      errResult.model_used = model;
      return res.status(200).json(errResult);
    }

    const { image } = req.body || {};
    const imageDataUrl = normalizeImageToDataUrl(image);
    if (!imageDataUrl) {
      const errResult = normalizeResult(
        buildErrorResult("NO_IMAGE", "image (base64 string) is required", model)
      );
      errResult.model_used = model;
      return res.status(200).json(errResult);
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
          json_schema: {
            name: JSON_SCHEMA.name,
            schema: JSON_SCHEMA.schema,
            strict: true,
          },
        },
      },
      temperature: 0.2,
      max_output_tokens: 1000
    };

    const guardResult = await isStoolImageGuard({
      apiKey,
      model,
      imageDataUrl,
      callOpenAIWithRetry,
      extractOutputText,
    });
    console.log(
      `[GUARD] is_stool=${guardResult.is_stool} confidence=${guardResult.confidence} reason=${guardResult.reason}`
    );
    if (!guardResult.is_stool) {
      const notStool = normalizeResult(buildNotStoolResult(guardResult));
      notStool.model_used = guardResult.model_used || model;
      res.setHeader("x-openai-model", notStool.model_used || "unknown");
      res.setHeader("schema_version", "2");
      return res.status(200).json(notStool);
    }

    console.log(`[OPENAI] request model=${model} text.format=json_schema`);
    const initialResponse = await callOpenAIWithRetry(apiKey, payload, model);
    const { r, raw } = initialResponse;
    let usedModel = initialResponse.model;
    console.log(`[OPENAI] response status=${r.status}`);
    res.setHeader("x-openai-model", usedModel || model);

    if (!r.ok) {
      const errResult = normalizeResult(
        buildErrorResult("OPENAI_ERROR", raw || `OpenAI failed (${r.status})`, usedModel)
      );
      errResult.model_used = usedModel;
      res.setHeader("x-openai-model", usedModel || model);
      return res.status(200).json(errResult);
    }

    const data = JSON.parse(raw);
    const outputText = extractOutputText(data);
    if (!outputText) {
      const errResult = normalizeResult(
        buildErrorResult("EMPTY_OUTPUT", "OpenAI response missing output text", usedModel)
      );
      errResult.model_used = usedModel;
      res.setHeader("x-openai-model", usedModel || model);
      return res.status(200).json(errResult);
    }

    let parsed;
    const cleanedText = sanitizeRawText(outputText);
    try {
      parsed = JSON.parse(cleanedText);
    } catch (e) {
      console.log(
        `[PARSE_FAIL] output_text preview=${String(outputText || "").slice(0, 300)}`
      );
      const extracted = extractJsonFromText(cleanedText);
      if (extracted) {
        try {
          parsed = JSON.parse(extracted);
        } catch {
          parsed = null;
        }
      }
      if (!parsed) {
        const strictPayload = buildStrictPayload(payload);
        const retry = await callOpenAI(apiKey, strictPayload, model);
        if (retry.r.ok) {
          const retryData = JSON.parse(retry.raw);
          const retryText = extractOutputText(retryData);
          const retryCleaned = sanitizeRawText(retryText || "");
          try {
            parsed = JSON.parse(retryCleaned);
            usedModel = retry.model;
          } catch (retryErr) {
            const retryExtracted = extractJsonFromText(retryCleaned);
            if (retryExtracted) {
              try {
                parsed = JSON.parse(retryExtracted);
                usedModel = retry.model;
              } catch {
                parsed = null;
              }
            } else {
              parsed = null;
            }
          }
        }
      }
      if (!parsed) {
        const requestId = r.headers.get("x-request-id") || "";
        const fallback = normalizeResult(buildModelOutputInvalid(usedModel, requestId));
        fallback.raw_preview = String(cleanedText).slice(0, 500);
        fallback.model_used = usedModel;
        res.setHeader("x-openai-model", usedModel || model);
        return res.status(200).json(fallback);
      }
    }

    const normalized = normalizeResult(parsed);
    normalized.model_used = usedModel;
    if ((req.body?.context || req.body?.context_input) && !normalized.context_input) {
      normalized.context_input = req.body.context || req.body.context_input;
    }
    if ((req.body?.context || req.body?.context_input) && !normalized.input_context) {
      normalized.input_context = req.body.context || req.body.context_input;
    }
    if (!normalized.input_echo || typeof normalized.input_echo !== "object") {
      normalized.input_echo = { context: req.body?.context || req.body?.context_input || {} };
    } else if (!normalized.input_echo.context || typeof normalized.input_echo.context !== "object") {
      normalized.input_echo.context = req.body?.context || req.body?.context_input || {};
    }
    res.setHeader("schema_version", String(normalized.schema_version || 2));
    res.setHeader("x-openai-model", usedModel || model);
    return res.status(200).json(normalized);
  } catch (err) {
    console.error("proxy /analyze error", err);
    const errResult = normalizeResult(
      buildErrorResult("PROXY_EXCEPTION", String(err?.message || err), getPrimaryModel())
    );
    errResult.model_used = getPrimaryModel();
    res.setHeader("x-openai-model", getPrimaryModel());
    return res.status(200).json(errResult);
  }
});

const port = process.env.PORT || 10000;
app.listen(port, () => console.log(`OpenAI proxy listening on port ${port}`));
