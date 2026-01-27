import { adviceSchema, analyzeSchema, validateImageSchema } from "./schemas";

type OpenAIResponse<T> = { output_parsed: T };

export async function callOpenAI<T>(
  requestId: string,
  apiKey: string,
  model: string,
  timeoutMs: number,
  input: unknown,
  schema:
    | typeof validateImageSchema
    | typeof analyzeSchema
    | typeof adviceSchema
): Promise<T> {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), timeoutMs);
  const response = await fetch("https://api.openai.com/v1/responses", {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${apiKey}`,
      "Content-Type": "application/json",
      "X-Request-Id": requestId,
    },
    body: JSON.stringify({
      model,
      input,
      response_format: {
        type: "json_schema",
        json_schema: {
          name: "structured_output",
          schema,
          strict: true,
        },
      },
    }),
    signal: controller.signal,
  });
  clearTimeout(timeout);
  if (!response.ok) {
    const text = await response.text();
    throw new Error(`upstream_error:${response.status}:${text}`);
  }
  const data = (await response.json()) as OpenAIResponse<T>;
  if (!data.output_parsed) {
    throw new Error("upstream_error:empty_output");
  }
  return data.output_parsed;
}
