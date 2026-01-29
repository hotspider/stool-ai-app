export const V2_SCHEMA_JSON = {
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "StoolAnalysisV2",
  "type": "object",
  "additionalProperties": false,
  "required": [
    "ok",
    "schema_version",
    "is_stool_image",
    "headline",
    "score",
    "risk_level",
    "confidence",
    "uncertainty_note",
    "stool_features",
    "doctor_explanation",
    "possible_causes",
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
    "is_stool_image": { "type": "boolean" },
    "headline": { "type": "string", "minLength": 1 },
    "score": { "type": "integer", "minimum": 0, "maximum": 100 },
    "risk_level": { "type": "string", "enum": ["low", "medium", "high", "unknown"] },
    "confidence": { "type": "number", "minimum": 0, "maximum": 1 },
    "uncertainty_note": { "type": "string" },
    "stool_features": {
      "type": ["object", "null"],
      "additionalProperties": false,
      "required": [
        "shape",
        "bristol_type",
        "bristol_range",
        "shape_desc",
        "color",
        "color_desc",
        "color_reason",
        "texture",
        "texture_desc",
        "abnormal_signs",
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
        "shape": { "type": "string", "minLength": 1 },
        "bristol_type": { "type": ["integer", "null"], "minimum": 1, "maximum": 7 },
        "bristol_range": { "type": "string", "minLength": 1 },
        "shape_desc": { "type": "string", "minLength": 1 },
        "color": { "type": "string", "minLength": 1 },
        "color_desc": { "type": "string", "minLength": 1 },
        "color_reason": { "type": "string", "minLength": 1 },
        "texture": { "type": "string", "minLength": 1 },
        "texture_desc": { "type": "string", "minLength": 1 },
        "abnormal_signs": {
          "type": "array",
          "items": { "type": "string", "minLength": 1 },
          "minItems": 1
        },
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
    "doctor_explanation": {
      "type": ["object", "null"],
      "additionalProperties": false,
      "required": [
        "one_sentence_conclusion",
        "shape",
        "color",
        "texture",
        "combined_judgement",
        "visual_analysis"
      ],
      "properties": {
        "one_sentence_conclusion": { "type": "string", "minLength": 1 },
        "shape": { "type": "string", "minLength": 1 },
        "color": { "type": "string", "minLength": 1 },
        "texture": { "type": "string", "minLength": 1 },
        "visual_analysis": {
          "type": "object",
          "additionalProperties": false,
          "required": ["shape", "color", "texture"],
          "properties": {
            "shape": { "type": "string", "minLength": 1 },
            "color": { "type": "string", "minLength": 1 },
            "texture": { "type": "string", "minLength": 1 }
          }
        },
        "combined_judgement": { "type": "string", "minLength": 1 }
      }
    },
    "possible_causes": {
      "type": "array",
      "minItems": 3,
      "items": {
        "type": "object",
        "additionalProperties": false,
        "required": ["title", "explanation"],
        "properties": {
          "title": { "type": "string", "minLength": 1 },
          "explanation": { "type": "string", "minLength": 1 }
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
    "input_context": { "type": "object" },
    "explanation": { "type": "string" },
    "error_code": { "type": "string" },
    "error": { "type": "string" },
    "message": { "type": "string" },
    "raw_preview": { "type": "string" },
    "openai_request_id": { "type": "string" }
  }
};
