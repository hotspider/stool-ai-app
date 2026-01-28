# OpenAI Vision Proxy (Express)

Lightweight Node.js + Express service that forwards `/analyze` requests to OpenAI
Vision and returns a structured JSON response.

## Endpoints

- `GET /ping` → `{ ok: true }`
- `POST /analyze`

### Request Body (JSON)

```json
{
  "image": "base64 string",
  "age_months": 30,
  "odor": "none",
  "pain_or_strain": false,
  "diet_keywords": "banana"
}
```

### Response (JSON)

```json
{
  "ok": true,
  "summary": "...",
  "risk_level": "low",
  "bristol_type": 4,
  "color": "brown",
  "texture": "normal",
  "hydration_hint": "...",
  "diet_advice": ["..."],
  "care_advice": ["..."],
  "disclaimer": "..."
}
```

## Local Run

```bash
npm install
OPENAI_API_KEY=your_key npm start
```

## Render Deployment

1. Create a new **Web Service** on Render.
2. Set **Build Command**: `npm install`
3. Set **Start Command**: `npm start`
4. Add environment variable:
   - `OPENAI_API_KEY` = your OpenAI API key

Optional:
- `OPENAI_MODEL` to override model (default `gpt-4.1-mini`)
- `PORT` is provided by Render automatically

