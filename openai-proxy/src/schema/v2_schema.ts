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
    "interpretation",
    "reasoning_bullets",
    "actions_today",
    "red_flags",
    "follow_up_questions",
    "ui_strings",
    "model_used",
    "proxy_version"
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
      "required": [
        "bristol_type",
        "bristol_range",
        "shape_desc",
        "color_desc",
        "texture_desc",
        "volume",
        "wateriness",
        "mucus",
        "foam",
        "blood",
        "undigested_food",
        "separation_layers",
        "odor_level",
        "visible_findings"
      ],
      "properties": {
        "bristol_type": { "type": ["integer", "null"], "minimum": 1, "maximum": 7 },
        "bristol_range": { "type": "string", "minLength": 1 },
        "shape_desc": { "type": "string", "minLength": 1 },
        "color_desc": { "type": "string", "minLength": 1 },
        "texture_desc": { "type": "string", "minLength": 1 },
        "volume": { "type": "string", "enum": ["small", "medium", "large", "unknown"] },
        "wateriness": { "type": "string", "enum": ["none", "mild", "moderate", "severe"] },
        "mucus": { "type": "string", "enum": ["none", "suspected", "present"] },
        "foam": { "type": "string", "enum": ["none", "suspected", "present"] },
        "blood": { "type": "string", "enum": ["none", "suspected", "present"] },
        "undigested_food": { "type": "string", "enum": ["none", "suspected", "present"] },
        "separation_layers": { "type": "string", "enum": ["none", "suspected", "present"] },
        "odor_level": { "type": "string", "enum": ["normal", "strong", "very_strong", "unknown"] },
        "visible_findings": {
          "type": "array",
          "items": { "type": "string", "minLength": 1 },
          "minItems": 1
        }
      }
    },
    "interpretation": {
      "type": "object",
      "additionalProperties": false,
      "required": [
        "overall_judgement",
        "why_shape",
        "why_color",
        "why_texture",
        "how_context_affects",
        "confidence_explain"
      ],
      "properties": {
        "overall_judgement": { "type": "string", "minLength": 1 },
        "why_shape": { "type": "array", "items": { "type": "string", "minLength": 1 }, "minItems": 2 },
        "why_color": { "type": "array", "items": { "type": "string", "minLength": 1 }, "minItems": 2 },
        "why_texture": { "type": "array", "items": { "type": "string", "minLength": 1 }, "minItems": 2 },
        "how_context_affects": { "type": "array", "items": { "type": "string", "minLength": 1 }, "minItems": 3 },
        "confidence_explain": { "type": "string", "minLength": 1 }
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
      "required": ["diet", "hydration", "care", "avoid", "observe"],
      "properties": {
        "diet": { "type": "array", "items": { "type": "string", "minLength": 1 }, "minItems": 3 },
        "hydration": { "type": "array", "items": { "type": "string", "minLength": 1 }, "minItems": 3 },
        "care": { "type": "array", "items": { "type": "string", "minLength": 1 }, "minItems": 3 },
        "avoid": { "type": "array", "items": { "type": "string", "minLength": 1 }, "minItems": 3 },
        "observe": { "type": "array", "items": { "type": "string", "minLength": 1 }, "minItems": 3 }
      }
    },
    "red_flags": {
      "type": "array",
      "minItems": 5,
      "items": {
        "type": "object",
        "additionalProperties": false,
        "required": ["title", "detail"],
        "properties": {
          "title": { "type": "string", "minLength": 1 },
          "detail": { "type": "string", "minLength": 1 }
        }
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
        "tags": { "type": "array", "items": { "type": "string", "minLength": 1 }, "minItems": 0 },
        "sections": {
          "type": "array",
          "minItems": 4,
          "items": {
            "type": "object",
            "additionalProperties": false,
            "required": ["title", "icon_key", "items"],
            "properties": {
              "title": { "type": "string", "minLength": 1 },
              "icon_key": {
                "type": "string",
                "enum": ["diet", "hydration", "care", "warning", "question", "camera", "retry", "observe", "info"]
              },
              "items": { "type": "array", "items": { "type": "string", "minLength": 1 }, "minItems": 3 }
            }
          }
        },
        "longform": {
          "type": "object",
          "additionalProperties": false,
          "required": [
            "conclusion",
            "how_to_read",
            "context",
            "causes",
            "todo",
            "red_flags",
            "reassure"
          ],
          "properties": {
            "conclusion": { "type": "string", "minLength": 1 },
            "how_to_read": { "type": "string", "minLength": 1 },
            "context": { "type": "string", "minLength": 1 },
            "causes": { "type": "string", "minLength": 1 },
            "todo": { "type": "string", "minLength": 1 },
            "red_flags": { "type": "string", "minLength": 1 },
            "reassure": { "type": "string", "minLength": 1 }
          }
        }
      }
    },
    "model_used": { "type": "string", "minLength": 1 },
    "proxy_version": { "type": "string", "minLength": 1 },
    "worker_version": { "type": "string" },
    "context_input": { "type": "object" },
    "error_code": { "type": "string" },
    "error": { "type": "string" },
    "message": { "type": "string" },
    "raw_preview": { "type": "string" },
    "openai_request_id": { "type": "string" }
  }
};
