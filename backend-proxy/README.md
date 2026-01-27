# Backend Proxy（OpenAI Responses API）

本目录提供一个最小可用的 OpenAI 后端代理，支持图片输入与结构化 JSON 输出。

## 功能接口

- `POST /v1/validate-image`  
  入参：`{ image_base64: string, image_mime?: string }`  
  出参：`{ is_stool: boolean, confidence: number, reason: string }`

- `POST /v1/analyze`  
  入参：`{ image_base64: string, image_mime?: string }`  
  出参：严格符合 AnalyzeResponse schema

- `POST /v1/advice`  
  入参：`{ analysis: AnalyzeResponse, user_inputs: UserInputs }`  
  出参：严格符合 AdviceResponse schema

## 本地运行

```bash
cd backend-proxy
cp env.example .env
# 编辑 .env 填写 OPENAI_API_KEY
npm install
npm run dev
```

## 部署（Cloudflare Workers）

```bash
cd backend-proxy
npm install
npm run deploy
```

首次部署需要登录：

```bash
npx wrangler login
```

设置环境变量：

```bash
npx wrangler secret put OPENAI_API_KEY
```

## cURL 测试示例

> 注意：请将 `IMAGE_BASE64` 替换为图片的 base64 字符串（不含 data:image 前缀）。

```bash
curl -X POST https://<your-worker>.workers.dev/v1/validate-image \
  -H "Content-Type: application/json" \
  -d '{"image_base64":"IMAGE_BASE64","image_mime":"image/jpeg"}'
```

```bash
curl -X POST https://<your-worker>.workers.dev/v1/analyze \
  -H "Content-Type: application/json" \
  -d '{"image_base64":"IMAGE_BASE64","image_mime":"image/jpeg"}'
```

```bash
curl -X POST https://<your-worker>.workers.dev/v1/advice \
  -H "Content-Type: application/json" \
  -d '{
    "analysis": {
      "riskLevel": "low",
      "summary": "整体表现较稳定，可先继续观察。",
      "bristolType": 4,
      "color": "brown",
      "texture": "normal",
      "suspiciousSignals": [],
      "qualityScore": 82,
      "qualityIssues": [],
      "analyzedAt": "2025-01-01T12:00:00Z"
    },
    "user_inputs": {
      "odor": "无",
      "painOrStrain": false,
      "dietKeywords": ""
    }
  }'
```

## 约束与安全

- OpenAI API Key 仅存放在服务端环境变量。
- 日志不会记录原始图片，只记录 requestId 与耗时。
