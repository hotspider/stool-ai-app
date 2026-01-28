const express = require("express");
const cors = require("cors");

const app = express();
app.use(cors());
app.use(express.json({ limit: "25mb" }));

const DEFAULT_MODEL = "gpt-4.1-mini";

app.get("/ping", (_req, res) => {
  res.json({ ok: true });
});

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

    const {
      image,
      age_months,
      odor,
      pain_or_strain,
      diet_keywords
    } = req.body || {};

    if (!image || typeof image !== "string") {
      return res.status(400).json({
        ok: false,
        error: "NO_IMAGE",
        message: "image (base64 string) is required"
      });
    }

    const model = process.env.OPENAI_MODEL || DEFAULT_MODEL;
    const imageDataUrl = image.startsWith("data:")
      ? image
      : `data:image/jpeg;base64,${image}`;

    const systemPrompt = [
      "You are a pediatric stool-analysis assistant.",
      "Return ONLY strict JSON with these fields:",
      "ok, summary, risk_level, bristol_type, color, texture,",
      "hydration_hint, diet_advice, care_advice, disclaimer.",
      "Rules:",
      "- ok is true if the image is stool/diaper-stool, else false.",
      "- risk_level is one of low|medium|high (use low if uncertain).",
      "- bristol_type is 1-7 or null if unclear.",
      "- color and texture are short strings (or null if unclear).",
      "- diet_advice and care_advice are arrays of short actionable items.",
      "- disclaimer is a short medical disclaimer."
    ].join("\n");

    const userPrompt = [
      "Analyze the image and generate structured advice.",
      `age_months: ${Number.isFinite(age_months) ? age_months : ""}`,
      `odor: ${typeof odor === "string" ? odor : ""}`,
      `pain_or_strain: ${Boolean(pain_or_strain)}`,
      `diet_keywords: ${typeof diet_keywords === "string" ? diet_keywords : ""}`
    ].join("\n");

    const payload = {
      model,
      input: [
        {
          role: "system",
          content: [{ type: "input_text", text: systemPrompt }]
        },
        {
          role: "user",
          content: [
            { type: "input_text", text: userPrompt },
            { type: "input_image", image_url: imageDataUrl }
          ]
        }
      ],
      text: { format: { type: "json" } },
      temperature: 0.2,
      max_output_tokens: 900
    };

    console.log(`[OPENAI] request model=${model} text.format=json`);
    const response = await fetch("https://api.openai.com/v1/responses", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${apiKey}`
      },
      body: JSON.stringify(payload)
    });
    console.log(`[OPENAI] response status=${response.status}`);

    if (!response.ok) {
      const errorText = await response.text().catch(() => "");
      let errorCode = "";
      try {
        const errorJson = JSON.parse(errorText);
        errorCode = errorJson?.error?.code || errorJson?.error?.type || "";
      } catch {
        errorCode = "";
      }
      if (errorCode) {
        console.log(`[OPENAI] error code=${errorCode}`);
      }
      return res.status(502).json({
        ok: false,
        error: "OPENAI_ERROR",
        message: errorText || `OpenAI request failed (${response.status})`
      });
    }

    const data = await response.json();
    const outputText = extractOutputText(data);
    if (!outputText) {
      return res.status(502).json({
        ok: false,
        error: "EMPTY_OUTPUT",
        message: "OpenAI response missing output text"
      });
    }

    let parsed;
    try {
      parsed = JSON.parse(outputText);
    } catch (err) {
      return res.status(502).json({
        ok: false,
        error: "INVALID_JSON",
        message: "OpenAI returned non-JSON output"
      });
    }

    const normalized = normalizeOutput(parsed);
    return res.json(normalized);
  } catch (error) {
    return res.status(500).json({
      ok: false,
      error: "INTERNAL_ERROR",
      message: error?.message || "Unexpected error"
    });
  }
});

function extractOutputText(data) {
  if (!data) return "";
  if (typeof data.output_text === "string") return data.output_text;
  const output = Array.isArray(data.output) ? data.output : [];
  for (const item of output) {
    const content = Array.isArray(item.content) ? item.content : [];
    for (const c of content) {
      if (c && c.type === "output_text" && typeof c.text === "string") {
        return c.text;
      }
    }
  }
  return "";
}

function normalizeOutput(parsed) {
  const obj = parsed && typeof parsed === "object" ? parsed : {};
  return {
    ok: Boolean(obj.ok),
    summary: typeof obj.summary === "string" ? obj.summary : "",
    risk_level:
      typeof obj.risk_level === "string" ? obj.risk_level : "low",
    bristol_type:
      typeof obj.bristol_type === "number" ? obj.bristol_type : null,
    color: typeof obj.color === "string" ? obj.color : null,
    texture: typeof obj.texture === "string" ? obj.texture : null,
    hydration_hint:
      typeof obj.hydration_hint === "string" ? obj.hydration_hint : "",
    diet_advice: Array.isArray(obj.diet_advice) ? obj.diet_advice : [],
    care_advice: Array.isArray(obj.care_advice) ? obj.care_advice : [],
    disclaimer:
      typeof obj.disclaimer === "string"
        ? obj.disclaimer
        : "This result is for general guidance and not medical diagnosis."
  };
}

const port = Number(process.env.PORT) || 3000;
app.listen(port, () => {
  console.log(`OpenAI proxy listening on port ${port}`);
});
