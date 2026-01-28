type Env = {
  OPENAI_API_KEY: string;
};

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "Content-Type, Authorization",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
};

const MAX_IMAGE_BYTES = 1024 * 1024;
const OPENAI_TIMEOUT_MS = 12000;
const RATE_LIMIT_WINDOW_MS = 60_000;
const RATE_LIMIT_MAX = 10;
const rateLimitStore = new Map<string, number[]>();

export default {
  async fetch(request: Request, env: Env, ctx: ExecutionContext): Promise<Response> {
    console.log("[REQ]", request.method, new URL(request.url).pathname);
    void ctx;
    const url = new URL(request.url);

    if (request.method === "OPTIONS") {
      return new Response(null, { status: 204, headers: corsHeaders });
    }

    if (request.method === "GET" && url.pathname === "/") {
      return jsonOk({
        ok: true,
        service: "stool-ai-worker",
        hasKey: Boolean(env.OPENAI_API_KEY),
      });
    }

    if (request.method === "POST" && url.pathname === "/analyze") {
      console.log("[ANALYZE_ENTER]", request.headers.get("content-type"));
      if (!env.OPENAI_API_KEY) {
        const flag = "missing_key";
        console.log("[ANALYZE_EXIT]", flag);
        return jsonError(500, "missing_key", "OPENAI_API_KEY 未配置");
      }

      const body = await request.json().catch(() => null);
      if (!body || typeof body !== "object") {
        const flag = "invalid_body";
        console.log("[ANALYZE_EXIT]", flag);
        return jsonError(400, "invalid_body", "请求体无效");
      }

      const payload = body as Record<string, unknown>;
      const imageBase64 = payload.imageBase64;
      const locale = resolveLocale(payload.locale, request.headers.get("accept-language"));
      const ip = getClientIp(request.headers) ?? "local";
      if (isRateLimited(ip)) {
        const flag = "RATE_LIMITED";
        console.log("[ANALYZE_EXIT]", flag);
        return jsonOk({
          ok: false,
          error: flag,
          message: i18n(locale, "rate_limited_message"),
          suggestion: i18n(locale, "rate_limited_suggestion"),
        });
      }
      const imageDataUrl = normalizeImage(imageBase64);
      if (!imageDataUrl) {
        const flag = "invalid_image";
        console.log("[ANALYZE_EXIT]", flag);
        return jsonError(400, "invalid_image", "图片无效或为空");
      }
      const imageBytes = estimateBase64Bytes(imageBase64);
      if (imageBytes > MAX_IMAGE_BYTES) {
        const flag = "IMAGE_TOO_LARGE";
        console.log("[ANALYZE_EXIT]", flag);
        return jsonOk({
          ok: false,
          error: flag,
          message: i18n(locale, "image_too_large_message"),
          suggestion: i18n(locale, "image_too_large_suggestion"),
        });
      }

      try {
        const result = await callOpenAIVision(env.OPENAI_API_KEY, imageDataUrl, locale);
        const detection = normalizeDetection(result);
        if (detection.detectStatus !== "confirmed") {
          const errorCode =
            detection.detectStatus === "rejected" ? "NOT_STOOL" : "AI_UNCERTAIN";
          const responseObject = {
            ok: false,
            error: errorCode,
            message:
              detection.reason ?? i18n(locale, "uncertain_message"),
            suggestion: i18n(locale, "uncertain_suggestion"),
            detectStatus: detection.detectStatus,
            confidence: detection.confidence,
            scene: detection.scene,
            reason: detection.reason,
          };
          console.log("[ANALYZE_EXIT]", errorCode);
          console.log(
            "[ANALYZE_RESPONSE]",
            JSON.stringify(responseObject).slice(0, 1500)
          );
          return jsonOk(responseObject);
        }

        console.log("[ANALYZE_EXIT]", true);
        const responseObject = {
          detectStatus: detection.detectStatus,
          confidence: detection.confidence,
          scene: detection.scene,
          reason: detection.reason,
          analysis: result.analysis,
          advice: result.advice,
        };
        console.log(
          "[ANALYZE_RESPONSE]",
          JSON.stringify(responseObject).slice(0, 1500)
        );
        return jsonOk(responseObject);
      } catch (error) {
        if (isTimeoutError(error)) {
          const flag = "TIMEOUT";
          console.log("[ANALYZE_EXIT]", flag);
          return jsonOk({
            ok: false,
            error: flag,
            message: i18n(locale, "timeout_message"),
            suggestion: i18n(locale, "timeout_suggestion"),
          });
        }
        console.log("[ANALYZE_EXIT]", "upstream_error");
        return jsonError(500, "upstream_error", "上游服务错误");
      }
    }

    return jsonError(404, "not_found", "接口不存在");
  },
};

async function callOpenAIVision(
  apiKey: string,
  imageDataUrl: string,
  locale: LocaleCode
) {
  const prompt =
    "你是婴幼儿尿不湿识别助手（Phase 6.2）。\n" +
    "任务：判断图片是否为婴幼儿尿不湿/纸尿裤/宝宝便便场景，并输出结构化 JSON。\n" +
    "支持场景：diaper / nappy / baby stool。\n" +
    "必须只输出 JSON，不要输出其他内容。\n" +
    `请仅使用 ${localeName(locale)} 输出结果。\n` +
    "返回结构固定：\n" +
    "{\n" +
    "  \"detectStatus\": \"confirmed|uncertain|rejected\",\n" +
    "  \"confidence\": 0-1,\n" +
    "  \"scene\": \"diaper|nappy|baby_stool|other\",\n" +
    "  \"reason\": \"简短原因\",\n" +
    "  \"analysis\": {\n" +
    "    \"riskLevel\": \"low|medium|high\",\n" +
    "    \"summary\": \"一句话总结\",\n" +
    "    \"bristolType\": 1-7,\n" +
    "    \"color\": \"brown|yellow|green|black|red|pale|mixed|unknown\",\n" +
    "    \"texture\": \"watery|mushy|normal|hard|oily|foamy|unknown\",\n" +
    "    \"suspiciousSignals\": [\"...\"],\n" +
    "    \"qualityScore\": 0-100,\n" +
    "    \"qualityIssues\": [\"...\"],\n" +
    "    \"analyzedAt\": \"ISO8601\"\n" +
    "  },\n" +
    "  \"advice\": {\n" +
    "    \"summary\": \"建议总结\",\n" +
    "    \"next48hActions\": [\"...\"],\n" +
    "    \"seekCareIf\": [\"...\"],\n" +
    "    \"disclaimers\": [\"...\" ]\n" +
    "  }\n" +
    "}\n" +
    "当 detectStatus != confirmed 时，不生成 analysis/advice（可返回 null）。";

  const resp = await fetchWithTimeout(
    "https://api.openai.com/v1/chat/completions",
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${apiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: "gpt-4.1-mini",
        temperature: 0.2,
        max_tokens: 500,
        response_format: { type: "json_object" },
        messages: [
          { role: "system", content: prompt },
          {
            role: "user",
            content: [
              { type: "text", text: "请根据图片输出结构化 JSON。" },
              { type: "image_url", image_url: { url: imageDataUrl } },
            ],
          },
        ],
      }),
    }
  );

  if (!resp.ok) {
    throw new Error(`OpenAI error: ${resp.status}`);
  }

  const data = (await resp.json()) as {
    choices?: Array<{ message?: { content?: string } }>;
  };
  const content = data.choices?.[0]?.message?.content ?? "";
  const parsed = safeJsonParse(content);
  if (!parsed || typeof parsed !== "object") {
    throw new Error("Invalid model output");
  }
  return parsed as {
    detectStatus?: string;
    confidence?: number;
    scene?: string;
    reason?: string;
    analysis?: unknown;
    advice?: unknown;
  };
}

function normalizeImage(imageBase64: unknown): string | null {
  if (!imageBase64 || typeof imageBase64 !== "string") {
    return null;
  }
  const clean = imageBase64.replace(/^data:image\/[a-zA-Z]+;base64,/, "");
  if (clean.length < 64) {
    return null;
  }
  return `data:image/jpeg;base64,${clean}`;
}

function safeJsonParse(text: string) {
  try {
    return JSON.parse(text);
  } catch (_) {
    return null;
  }
}

function estimateBase64Bytes(imageBase64: unknown): number {
  if (typeof imageBase64 !== "string") {
    return 0;
  }
  const clean = imageBase64.replace(/^data:image\/[a-zA-Z]+;base64,/, "");
  return Math.floor((clean.length * 3) / 4);
}

function getClientIp(headers: Headers): string | null {
  const cf = headers.get("cf-connecting-ip");
  if (cf) {
    return cf;
  }
  const forwarded = headers.get("x-forwarded-for");
  if (!forwarded) {
    return null;
  }
  return forwarded.split(",")[0]?.trim() ?? null;
}

function isRateLimited(ip: string): boolean {
  const now = Date.now();
  const windowStart = now - RATE_LIMIT_WINDOW_MS;
  const list = rateLimitStore.get(ip) ?? [];
  const recent = list.filter((ts) => ts >= windowStart);
  recent.push(now);
  rateLimitStore.set(ip, recent);
  return recent.length > RATE_LIMIT_MAX;
}

async function fetchWithTimeout(
  url: string,
  init: RequestInit
): Promise<Response> {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort("timeout"), OPENAI_TIMEOUT_MS);
  try {
    return await fetch(url, { ...init, signal: controller.signal });
  } finally {
    clearTimeout(timeout);
  }
}

function isTimeoutError(error: unknown): boolean {
  if (!error) {
    return false;
  }
  const name = (error as { name?: string }).name;
  if (name === "AbortError") {
    return true;
  }
  const message = String(error);
  return message.includes("timeout") || message.includes("AbortError");
}

function jsonOk(data: unknown): Response {
  return new Response(JSON.stringify(data), {
    status: 200,
    headers: { "Content-Type": "application/json", ...corsHeaders },
  });
}

function jsonError(code: number, type: string, message: string): Response {
  return new Response(JSON.stringify({ error: type, message }), {
    status: code,
    headers: { "Content-Type": "application/json", ...corsHeaders },
  });
}

function normalizeDetection(result: {
  detectStatus?: string;
  confidence?: number;
  scene?: string;
  reason?: string;
}) {
  const statusRaw = result.detectStatus?.toLowerCase().trim();
  const detectStatus =
    statusRaw === "confirmed" || statusRaw === "uncertain" || statusRaw === "rejected"
      ? (statusRaw as "confirmed" | "uncertain" | "rejected")
      : "uncertain";
  const confidence =
    typeof result.confidence === "number" && Number.isFinite(result.confidence)
      ? Math.max(0, Math.min(1, result.confidence))
      : 0;
  const sceneRaw = result.scene?.toLowerCase().trim();
  const scene =
    sceneRaw === "diaper" ||
    sceneRaw === "nappy" ||
    sceneRaw === "baby_stool" ||
    sceneRaw === "other"
      ? sceneRaw
      : "other";

  return {
    detectStatus,
    confidence,
    scene,
    reason: result.reason?.toString(),
  };
}

type LocaleCode = "zh" | "en" | "ja" | "ko" | "fr" | "de" | "es" | "id" | "th";

const SUPPORTED_LOCALES: LocaleCode[] = [
  "zh",
  "en",
  "ja",
  "ko",
  "fr",
  "de",
  "es",
  "id",
  "th",
];

function resolveLocale(
  bodyLocale: unknown,
  acceptLanguage: string | null
): LocaleCode {
  const candidate =
    normalizeLocale(bodyLocale) ?? parseAcceptLanguage(acceptLanguage);
  return SUPPORTED_LOCALES.includes(candidate as LocaleCode)
    ? (candidate as LocaleCode)
    : "en";
}

function normalizeLocale(value: unknown): string | null {
  if (typeof value !== "string") {
    return null;
  }
  const lang = value.toLowerCase().trim().split("-")[0];
  return lang.length ? lang : null;
}

function parseAcceptLanguage(value: string | null): string | null {
  if (!value) {
    return null;
  }
  const parts = value.split(",");
  for (const part of parts) {
    const lang = part.trim().split(";")[0];
    const normalized = normalizeLocale(lang);
    if (normalized && SUPPORTED_LOCALES.includes(normalized as LocaleCode)) {
      return normalized;
    }
  }
  return null;
}

function localeName(locale: LocaleCode): string {
  switch (locale) {
    case "zh":
      return "中文";
    case "ja":
      return "日语";
    case "ko":
      return "韩语";
    case "fr":
      return "法语";
    case "de":
      return "德语";
    case "es":
      return "西班牙语";
    case "id":
      return "印尼语";
    case "th":
      return "泰语";
    default:
      return "英语";
  }
}

function i18n(locale: LocaleCode, key: string): string {
  const table: Record<LocaleCode, Record<string, string>> = {
    zh: {
      not_stool_message: "未识别到目标",
      not_stool_suggestion: "请重新拍摄或选择更清晰的图片。",
      blurry_message: "图片较为模糊",
      blurry_suggestion: "请对焦后重新拍摄。",
      low_light_message: "光线不足",
      low_light_suggestion: "请在光线充足的环境拍摄。",
      uncertain_message: "图片无法识别",
      uncertain_suggestion: "请更换角度或重新拍摄。",
      image_too_large_message: "图片过大",
      image_too_large_suggestion: "请压缩或选择更小的图片。",
      timeout_message: "处理超时",
      timeout_suggestion: "请稍后重试。",
      rate_limited_message: "请求过于频繁",
      rate_limited_suggestion: "请稍后再试。",
    },
    en: {
      not_stool_message: "No target detected",
      not_stool_suggestion: "Please retake or choose a clearer image.",
      blurry_message: "Image is blurry",
      blurry_suggestion: "Please refocus and retake.",
      low_light_message: "Low light",
      low_light_suggestion: "Please shoot in better lighting.",
      uncertain_message: "Image cannot be recognized",
      uncertain_suggestion: "Please try another angle or retake.",
      image_too_large_message: "Image too large",
      image_too_large_suggestion: "Please compress or choose a smaller image.",
      timeout_message: "Request timed out",
      timeout_suggestion: "Please try again later.",
      rate_limited_message: "Too many requests",
      rate_limited_suggestion: "Please try again later.",
    },
    ja: {
      not_stool_message: "対象が認識できません",
      not_stool_suggestion: "撮り直すか、より鮮明な画像を選択してください。",
      blurry_message: "画像がぼやけています",
      blurry_suggestion: "ピントを合わせて撮り直してください。",
      low_light_message: "光が不足しています",
      low_light_suggestion: "明るい場所で撮影してください。",
      uncertain_message: "画像を認識できません",
      uncertain_suggestion: "角度を変えて撮り直してください。",
      image_too_large_message: "画像が大きすぎます",
      image_too_large_suggestion: "圧縮するか小さい画像を選択してください。",
      timeout_message: "処理がタイムアウトしました",
      timeout_suggestion: "時間をおいて再試行してください。",
      rate_limited_message: "リクエストが多すぎます",
      rate_limited_suggestion: "時間をおいて再試行してください。",
    },
    ko: {
      not_stool_message: "대상을 인식할 수 없습니다",
      not_stool_suggestion: "다시 촬영하거나 더 선명한 이미지를 선택하세요.",
      blurry_message: "이미지가 흐릿합니다",
      blurry_suggestion: "초점을 맞추고 다시 촬영하세요.",
      low_light_message: "조명이 부족합니다",
      low_light_suggestion: "더 밝은 곳에서 촬영하세요.",
      uncertain_message: "이미지를 인식할 수 없습니다",
      uncertain_suggestion: "각도를 바꿔 다시 촬영하세요.",
      image_too_large_message: "이미지가 너무 큽니다",
      image_too_large_suggestion: "압축하거나 더 작은 이미지를 선택하세요.",
      timeout_message: "요청 시간이 초과되었습니다",
      timeout_suggestion: "잠시 후 다시 시도하세요.",
      rate_limited_message: "요청이 너무 많습니다",
      rate_limited_suggestion: "잠시 후 다시 시도하세요.",
    },
    fr: {
      not_stool_message: "Cible non détectée",
      not_stool_suggestion: "Veuillez reprendre ou choisir une image plus nette.",
      blurry_message: "Image floue",
      blurry_suggestion: "Faites la mise au point et reprenez.",
      low_light_message: "Luminosité insuffisante",
      low_light_suggestion: "Prenez la photo dans un endroit plus lumineux.",
      uncertain_message: "Image non reconnue",
      uncertain_suggestion: "Essayez un autre angle ou reprenez.",
      image_too_large_message: "Image trop grande",
      image_too_large_suggestion: "Veuillez compresser ou choisir une image plus petite.",
      timeout_message: "Délai dépassé",
      timeout_suggestion: "Veuillez réessayer plus tard.",
      rate_limited_message: "Trop de requêtes",
      rate_limited_suggestion: "Veuillez réessayer plus tard.",
    },
    de: {
      not_stool_message: "Ziel nicht erkannt",
      not_stool_suggestion: "Bitte erneut aufnehmen oder ein klareres Bild wählen.",
      blurry_message: "Bild ist unscharf",
      blurry_suggestion: "Bitte fokussieren und erneut aufnehmen.",
      low_light_message: "Zu wenig Licht",
      low_light_suggestion: "Bitte bei besserem Licht aufnehmen.",
      uncertain_message: "Bild kann nicht erkannt werden",
      uncertain_suggestion: "Bitte anderen Winkel versuchen oder neu aufnehmen.",
      image_too_large_message: "Bild zu groß",
      image_too_large_suggestion: "Bitte komprimieren oder ein kleineres Bild wählen.",
      timeout_message: "Zeitüberschreitung",
      timeout_suggestion: "Bitte später erneut versuchen.",
      rate_limited_message: "Zu viele Anfragen",
      rate_limited_suggestion: "Bitte später erneut versuchen.",
    },
    es: {
      not_stool_message: "No se detectó el objetivo",
      not_stool_suggestion: "Vuelve a tomarla o elige una imagen más clara.",
      blurry_message: "La imagen está borrosa",
      blurry_suggestion: "Enfoca y vuelve a tomarla.",
      low_light_message: "Poca luz",
      low_light_suggestion: "Toma la foto con mejor iluminación.",
      uncertain_message: "No se puede reconocer la imagen",
      uncertain_suggestion: "Prueba otro ángulo o vuelve a tomarla.",
      image_too_large_message: "Imagen demasiado grande",
      image_too_large_suggestion: "Comprime o elige una imagen más pequeña.",
      timeout_message: "Tiempo de espera agotado",
      timeout_suggestion: "Inténtalo de nuevo más tarde.",
      rate_limited_message: "Demasiadas solicitudes",
      rate_limited_suggestion: "Inténtalo de nuevo más tarde.",
    },
    id: {
      not_stool_message: "Target tidak terdeteksi",
      not_stool_suggestion: "Silakan ambil ulang atau pilih gambar yang lebih jelas.",
      blurry_message: "Gambar buram",
      blurry_suggestion: "Fokuskan dan ambil ulang.",
      low_light_message: "Pencahayaan kurang",
      low_light_suggestion: "Ambil di tempat yang lebih terang.",
      uncertain_message: "Gambar tidak dapat dikenali",
      uncertain_suggestion: "Coba sudut lain atau ambil ulang.",
      image_too_large_message: "Gambar terlalu besar",
      image_too_large_suggestion: "Kompres atau pilih gambar yang lebih kecil.",
      timeout_message: "Permintaan kehabisan waktu",
      timeout_suggestion: "Silakan coba lagi nanti.",
      rate_limited_message: "Terlalu banyak permintaan",
      rate_limited_suggestion: "Silakan coba lagi nanti.",
    },
    th: {
      not_stool_message: "ไม่พบวัตถุเป้าหมาย",
      not_stool_suggestion: "กรุณาถ่ายใหม่หรือเลือกรูปที่ชัดเจนกว่า",
      blurry_message: "ภาพไม่ชัด",
      blurry_suggestion: "กรุณาโฟกัสแล้วถ่ายใหม่",
      low_light_message: "แสงน้อย",
      low_light_suggestion: "กรุณาถ่ายในที่สว่างขึ้น",
      uncertain_message: "ไม่สามารถระบุภาพได้",
      uncertain_suggestion: "ลองเปลี่ยนมุมหรือถ่ายใหม่",
      image_too_large_message: "รูปภาพใหญ่เกินไป",
      image_too_large_suggestion: "กรุณาบีบอัดหรือเลือกรูปที่เล็กกว่า",
      timeout_message: "หมดเวลาในการประมวลผล",
      timeout_suggestion: "กรุณาลองใหม่อีกครั้งภายหลัง",
      rate_limited_message: "มีคำขอมากเกินไป",
      rate_limited_suggestion: "กรุณาลองใหม่อีกครั้งภายหลัง",
    },
  };

  return table[locale]?.[key] ?? table.en[key] ?? "";
}
