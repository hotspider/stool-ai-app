const GUARD_SYSTEM_PROMPT = `
You are an image classifier.

Task:
Determine whether the given image contains human stool (feces).

Rules:
- Answer strictly in JSON (no markdown / no extra text).
- Do NOT analyze health, color, texture, or risks.
- Only judge if this is stool or NOT.
- Keep reason concise (max 3 short points).

Output JSON schema:
{
  "is_stool": boolean,
  "confidence": number,
  "reason": string
}

Examples:
- A photo of poop in a diaper -> is_stool: true
- A toy, food, animal, floor, body part, urine, vomit -> is_stool: false
`.trim();

const GUARD_SCHEMA = {
  name: "stool_image_guard",
  strict: true,
  schema: {
    type: "object",
    additionalProperties: false,
    required: ["is_stool", "confidence", "reason"],
    properties: {
      is_stool: { type: "boolean" },
      confidence: { type: "number", minimum: 0, maximum: 1 },
      reason: { type: "string", minLength: 1 },
    },
  },
};

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
          name: GUARD_SCHEMA.name,
          schema: GUARD_SCHEMA.schema,
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
      model_used: result?.model || model,
    };
  }

  return {
    is_stool: parsed.is_stool === true,
    confidence: Number.isFinite(Number(parsed.confidence))
      ? Number(parsed.confidence)
      : 0,
    reason: typeof parsed.reason === "string" ? parsed.reason : "无法识别图片类型。",
    model_used: result?.model || model,
  };
}

module.exports = { isStoolImageGuard };
