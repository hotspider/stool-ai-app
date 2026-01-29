const GUARD_SYSTEM_PROMPT = `
You are an image classifier.

Task:
Determine whether the given image contains human stool (feces).

Rules:
- Answer strictly in JSON (no markdown / no extra text).
- Do NOT analyze health, color, texture, or risks.
- Only judge if this is stool or NOT.
- Keep reason concise (max 3 short points).
- IMPORTANT: Mushy/watery stool, mashed-potato texture, soft paste, or stool spread on diaper/potty/tissue are ALL considered stool.
- Do NOT reject just because it is not formed.
- If background is messy or target is unclear, lower confidence instead of saying NOT stool.

Output JSON schema:
{
  "is_stool_image": boolean,
  "stool_confidence": number,
  "stool_scene": "diaper" | "toilet" | "potty" | "tissue" | "floor" | "unknown",
  "stool_form_hint": "watery" | "mushy" | "soft" | "formed" | "pellets" | "mixed" | "unknown",
  "not_stool_reason": string,
  "stool_detection_rationale": string
}

Examples:
- A photo of poop in a diaper -> is_stool: true
- A toy, food, animal, floor, body part, urine, vomit -> is_stool: false
`.trim();

import { DETECTION_SCHEMA } from "../../schema/detection_schema";

function sanitize(raw) {
  if (!raw) return "";
  let cleaned = raw.trim();
  cleaned = cleaned.replace(/^```(?:json)?/i, "").replace(/```$/i, "");
  return cleaned.trim();
}

function extractJson(text) {
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

async function isStoolImageGuard({
  apiKey,
  model,
  imageDataUrl,
  callOpenAIWithRetry,
  extractOutputText,
}) {
  const payload = {
    input: [
      {
        role: "system",
        content: [{ type: "input_text", text: GUARD_SYSTEM_PROMPT }],
      },
      {
        role: "user",
        content: [
          { type: "input_text", text: "Classify the image." },
          { type: "input_image", image_url: imageDataUrl },
        ],
      },
    ],
    text: {
      format: {
        type: "json_schema",
        json_schema: {
          name: DETECTION_SCHEMA.name,
          schema: DETECTION_SCHEMA.schema,
          strict: true,
        },
      },
    },
    temperature: 0,
    max_output_tokens: 200,
  };

  const result = await callOpenAIWithRetry(apiKey, payload, model);
  if (!result?.r?.ok) {
    return {
      is_stool: false,
      confidence: 0,
      reason: "无法识别图片类型，请重试或更换图片。",
      stool_confidence: 0,
      stool_scene: "unknown",
      stool_form_hint: "unknown",
      not_stool_reason: "无法识别图片类型，请重试或更换图片。",
      stool_detection_rationale: "图片内容不足以判断。",
      model_used: result?.model || model,
    };
  }

  const data = JSON.parse(result.raw);
  const text = extractOutputText(data);
  const cleaned = sanitize(text);
  let parsed = null;
  try {
    parsed = JSON.parse(cleaned);
  } catch {
    const extracted = extractJson(cleaned);
    if (extracted) {
      try {
        parsed = JSON.parse(extracted);
      } catch {
        parsed = null;
      }
    }
  }

  if (!parsed) {
    return {
      is_stool: false,
      confidence: 0,
      reason: "无法识别图片类型，请重试或更换图片。",
      stool_confidence: 0,
      stool_scene: "unknown",
      stool_form_hint: "unknown",
      not_stool_reason: "无法识别图片类型，请重试或更换图片。",
      stool_detection_rationale: "图片内容不足以判断。",
      model_used: result?.model || model,
    };
  }

  return {
    is_stool: parsed.is_stool_image === true,
    confidence: Number.isFinite(Number(parsed.stool_confidence))
      ? Number(parsed.stool_confidence)
      : 0,
    reason:
      typeof parsed.not_stool_reason === "string"
        ? parsed.not_stool_reason
        : "无法识别图片类型。",
    stool_confidence: Number.isFinite(Number(parsed.stool_confidence))
      ? Number(parsed.stool_confidence)
      : 0,
    stool_scene: parsed.stool_scene || "unknown",
    stool_form_hint: parsed.stool_form_hint || "unknown",
    not_stool_reason:
      typeof parsed.not_stool_reason === "string"
        ? parsed.not_stool_reason
        : "无法识别图片类型。",
    stool_detection_rationale:
      typeof parsed.stool_detection_rationale === "string"
        ? parsed.stool_detection_rationale
        : "图片内容不足以判断。",
    model_used: result?.model || model,
  };
}

module.exports = { isStoolImageGuard };
