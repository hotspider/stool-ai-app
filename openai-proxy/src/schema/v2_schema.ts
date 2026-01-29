export const V2_SCHEMA_JSON = {
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "StoolAnalysisV2",
  "type": "object",
  "additionalProperties": false,
  "required": [
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
    "diet_advice"
  ],
  "properties": {
    "ok": { "type": "boolean" },
    "schema_version": { "type": "integer", "enum": [2] },
    "headline": { "type": "string", "minLength": 1 },
    "score": { "type": "integer", "minimum": 0, "maximum": 100 },
    "risk_level": { "type": "string", "enum": ["low", "medium", "high", "unknown"] },
    "confidence": { "type": "number", "minimum": 0, "maximum": 1 },
    "uncertainty_note": { "type": "string" },
    "stool_features": {
      "type": "object",
      "additionalProperties": false,
      "required": ["bristol_type", "color", "texture", "volume", "visible_findings"],
      "properties": {
        "bristol_type": { "type": ["integer", "null"], "minimum": 1, "maximum": 7 },
        "color": { "type": ["string", "null"] },
        "texture": { "type": ["string", "null"] },
        "volume": { "type": "string", "enum": ["small", "normal", "large", "unknown"] },
        "visible_findings": {
          "type": "array",
          "items": { "type": "string" },
          "minItems": 0
        }
      }
    },
    "reasoning_bullets": {
      "type": "array",
      "items": { "type": "string", "minLength": 1 },
      "minItems": 5
    },
    "actions_today": {
      "type": "object",
      "additionalProperties": false,
      "required": ["diet", "hydration", "care", "avoid"],
      "properties": {
        "diet": { "type": "array", "items": { "type": "string" }, "minItems": 2 },
        "hydration": { "type": "array", "items": { "type": "string" }, "minItems": 2 },
        "care": { "type": "array", "items": { "type": "string" }, "minItems": 2 },
        "avoid": { "type": "array", "items": { "type": "string" }, "minItems": 2 }
      }
    },
    "red_flags": {
      "type": "array",
      "minItems": 5,
      "items": {
        "oneOf": [
          { "type": "string", "minLength": 1 },
          {
            "type": "object",
            "additionalProperties": false,
            "required": ["title", "detail"],
            "properties": {
              "title": { "type": "string", "minLength": 1 },
              "detail": { "type": "string", "minLength": 1 }
            }
          }
        ]
      }
    },
    "follow_up_questions": {
      "type": "array",
      "items": { "type": "string", "minLength": 1 },
      "minItems": 6
    },
    "ui_strings": {
      "type": "object",
      "additionalProperties": false,
      "required": ["summary", "tags", "sections"],
      "properties": {
        "summary": { "type": "string" },
        "tags": { "type": "array", "items": { "type": "string" }, "minItems": 0 },
        "sections": {
          "type": "array",
          "minItems": 4,
          "items": {
            "type": "object",
            "additionalProperties": false,
            "required": ["title", "icon_key", "items"],
            "properties": {
              "title": { "type": "string", "minLength": 1 },
              "icon_key": { "type": "string", "minLength": 1 },
              "items": { "type": "array", "items": { "type": "string", "minLength": 1 }, "minItems": 3 },
              "bullets": { "type": "array", "items": { "type": "string", "minLength": 1 }, "minItems": 0 }
            }
          }
        }
      }
    },
    "summary": { "type": "string" },
    "bristol_type": { "type": ["integer", "null"], "minimum": 1, "maximum": 7 },
    "color": { "type": ["string", "null"] },
    "texture": { "type": ["string", "null"] },
    "hydration_hint": { "type": "string" },
    "diet_advice": { "type": "array", "items": { "type": "string" }, "minItems": 0 }
  }
};
