import { adviceSchema, analyzeSchema, validateImageSchema } from "./schemas";
import { callOpenAI } from "./openai";
import type { AdviceResponse, AnalyzeResponse, ValidateImageResponse } from "./types";

type Env = {
  OPENAI_API_KEY: string;
  OPENAI_MODEL: string;
  REQUEST_TIMEOUT_MS: string;
};

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "Content-Type, Authorization",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const start = Date.now();
    const requestId = crypto.randomUUID();
    if (!env.OPENAI_API_KEY) {
      return jsonError(500, "config_error", "服务未配置", requestId);
    }

    if (request.method === "OPTIONS") {
      return new Response(null, { status: 204, headers: corsHeaders });
    }

    if (request.method !== "POST") {
      return jsonError(405, "method_not_allowed", "仅支持 POST", requestId);
    }

    try {
      const url = new URL(request.url);
      const body = await request.json().catch(() => null);
      if (!body || typeof body !== "object") {
        return jsonError(400, "invalid_request", "请求体无效", requestId);
      }

      if (url.pathname === "/v1/validate-image") {
        const { image_base64, image_mime } = body as Record<string, unknown>;
        const image = normalizeImage(image_base64, image_mime);
        if (!image) {
          return jsonError(400, "invalid_image", "图片无效或为空", requestId);
        }
        const result = await withRetry(() =>
          callOpenAI<ValidateImageResponse>(
            requestId,
            env.OPENAI_API_KEY,
            env.OPENAI_MODEL,
            Number(env.REQUEST_TIMEOUT_MS || 15000),
            buildValidateInput(image),
            validateImageSchema
          )
        );
        log(requestId, url.pathname, start, 200);
        return jsonOk(result);
      }

      if (url.pathname === "/v1/analyze") {
        const { image_base64, image_mime } = body as Record<string, unknown>;
        const image = normalizeImage(image_base64, image_mime);
        if (!image) {
          return jsonError(400, "invalid_image", "图片无效或为空", requestId);
        }
        const result = await withRetry(() =>
          callOpenAI<AnalyzeResponse>(
            requestId,
            env.OPENAI_API_KEY,
            env.OPENAI_MODEL,
            Number(env.REQUEST_TIMEOUT_MS || 15000),
            buildAnalyzeInput(image),
            analyzeSchema
          )
        );
        log(requestId, url.pathname, start, 200);
        return jsonOk(result);
      }

      if (url.pathname === "/v1/advice") {
        const { analysis, user_inputs } = body as Record<string, unknown>;
        if (!analysis || !user_inputs) {
          return jsonError(400, "invalid_request", "缺少分析或用户输入", requestId);
        }
        const result = await withRetry(() =>
          callOpenAI<AdviceResponse>(
            requestId,
            env.OPENAI_API_KEY,
            env.OPENAI_MODEL,
            Number(env.REQUEST_TIMEOUT_MS || 15000),
            buildAdviceInput(analysis, user_inputs),
            adviceSchema
          )
        );
        log(requestId, url.pathname, start, 200);
        return jsonOk(result);
      }

      return jsonError(404, "not_found", "接口不存在", requestId);
    } catch (error) {
      const code = mapErrorCode(error);
      log(requestId, new URL(request.url).pathname, start, code.http);
      return jsonError(code.http, code.code, code.message, requestId);
    }
  },
};

function normalizeImage(imageBase64: unknown, mime?: unknown): string | null {
  if (!imageBase64 || typeof imageBase64 !== "string") {
    return null;
  }
  const clean = imageBase64.replace(/^data:image\/[a-zA-Z]+;base64,/, "");
  if (clean.length < 64) {
    return null;
  }
  const imageMime = typeof mime === "string" ? mime : "image/jpeg";
  return `data:${imageMime};base64,${clean}`;
}

function buildValidateInput(imageDataUrl: string) {
  return [
    {
      role: "system",
      content: [
        {
          type: "text",
          text:
            "你是图像质检助手。判断图片是否为可用于大便分析的图片。" +
            "必须输出严格 JSON。",
        },
      ],
    },
    {
      role: "user",
      content: [
        { type: "input_text", text: "请判断是否为大便图片，给出原因。" },
        { type: "input_image", image_url: imageDataUrl },
      ],
    },
  ];
}

function buildAnalyzeInput(imageDataUrl: string) {
  return [
    {
      role: "system",
      content: [
        {
          type: "text",
          text:
            "你是健康识别助手。根据图片输出结构化分析，字段必须符合 schema。" +
            "analyzedAt 使用当前时间 ISO8601。",
        },
      ],
    },
    {
      role: "user",
      content: [
        { type: "input_text", text: "请给出结构化分析结果。" },
        { type: "input_image", image_url: imageDataUrl },
      ],
    },
  ];
}

function buildAdviceInput(analysis: unknown, userInputs: unknown) {
  return [
    {
      role: "system",
      content: [
        {
          type: "text",
          text:
            "你是健康建议助手。依据分析与用户输入输出结构化建议，字段必须符合 schema。",
        },
      ],
    },
    {
      role: "user",
      content: [
        {
          type: "input_text",
          text: JSON.stringify({ analysis, user_inputs: userInputs }),
        },
      ],
    },
  ];
}

function jsonOk(data: unknown): Response {
  return new Response(JSON.stringify(data), {
    status: 200,
    headers: { "Content-Type": "application/json", ...corsHeaders },
  });
}

function jsonError(
  status: number,
  code: string,
  message: string,
  requestId: string
): Response {
  return new Response(
    JSON.stringify({ error: { code, message, request_id: requestId } }),
    {
      status,
      headers: { "Content-Type": "application/json", ...corsHeaders },
    }
  );
}

function mapErrorCode(error: unknown): { http: number; code: string; message: string } {
  const text = String(error ?? "");
  if (text.includes("rate_limit") || text.includes("429")) {
    return { http: 429, code: "rate_limited", message: "请求过多，请稍后再试" };
  }
  if (text.includes("invalid_image")) {
    return { http: 400, code: "invalid_image", message: "图片无效或为空" };
  }
  if (text.includes("AbortError")) {
    return { http: 500, code: "upstream_error", message: "上游请求超时" };
  }
  return { http: 500, code: "upstream_error", message: "服务暂时不可用" };
}

function log(requestId: string, path: string, start: number, status: number) {
  const duration = Date.now() - start;
  console.log(
    JSON.stringify({
      requestId,
      path,
      status,
      duration_ms: duration,
    })
  );
}

async function withRetry<T>(fn: () => Promise<T>, retries = 1): Promise<T> {
  try {
    return await fn();
  } catch (error) {
    if (retries <= 0) {
      throw error;
    }
    return fn();
  }
}
