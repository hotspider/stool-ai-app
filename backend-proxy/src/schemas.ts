export const validateImageSchema = {
  type: "object",
  additionalProperties: false,
  required: ["is_stool", "confidence", "reason"],
  properties: {
    is_stool: { type: "boolean" },
    confidence: { type: "number", minimum: 0, maximum: 1 },
    reason: { type: "string" },
  },
} as const;

export const analyzeSchema = {
  type: "object",
  additionalProperties: false,
  required: [
    "riskLevel",
    "summary",
    "bristolType",
    "color",
    "texture",
    "suspiciousSignals",
    "qualityScore",
    "qualityIssues",
    "analyzedAt",
  ],
  properties: {
    riskLevel: { type: "string", enum: ["low", "medium", "high"] },
    summary: { type: "string" },
    bristolType: { type: "integer", minimum: 1, maximum: 7 },
    color: {
      type: "string",
      enum: ["brown", "yellow", "green", "black", "red", "pale", "mixed", "unknown"],
    },
    texture: {
      type: "string",
      enum: ["watery", "mushy", "normal", "hard", "oily", "foamy", "unknown"],
    },
    suspiciousSignals: { type: "array", items: { type: "string" } },
    qualityScore: { type: "integer", minimum: 0, maximum: 100 },
    qualityIssues: { type: "array", items: { type: "string" } },
    analyzedAt: { type: "string", format: "date-time" },
  },
} as const;

export const adviceSchema = {
  type: "object",
  additionalProperties: false,
  required: ["summary", "next48hActions", "seekCareIf", "disclaimers"],
  properties: {
    summary: { type: "string" },
    next48hActions: { type: "array", items: { type: "string" } },
    seekCareIf: { type: "array", items: { type: "string" } },
    disclaimers: { type: "array", items: { type: "string" } },
  },
} as const;
