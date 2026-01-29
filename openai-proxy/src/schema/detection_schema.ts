export const DETECTION_SCHEMA = {
  name: "stool_detection_v1",
  strict: true,
  schema: {
    type: "object",
    additionalProperties: false,
    required: [
      "is_stool_image",
      "stool_confidence",
      "stool_scene",
      "stool_form_hint",
      "not_stool_reason",
      "stool_detection_rationale",
    ],
    properties: {
      is_stool_image: { type: "boolean" },
      stool_confidence: { type: "number", minimum: 0, maximum: 1 },
      stool_scene: {
        type: "string",
        enum: ["diaper", "toilet", "potty", "tissue", "floor", "unknown"],
      },
      stool_form_hint: {
        type: "string",
        enum: ["watery", "mushy", "soft", "formed", "pellets", "mixed", "unknown"],
      },
      not_stool_reason: { type: "string", minLength: 1 },
      stool_detection_rationale: { type: "string", minLength: 1 },
    },
  },
};
