# Model routing and quota policy

Updated: 2026-11-06

## NVIDIA coding models

- `nvidia/nemotron-3-ultra-550b-a55b`: deep architecture reasoning, hard problem solving, planning and code review.
- `nvidia/nemotron-3.5-lightning-30b-a3b`: faster coding workhorse for routine implementation and repairs.

Correct spelling: **Nemotron**. NVIDIA's official model pages document reasoning/thinking mode. Their examples use temperature 1.0 and top_p 0.95; Lightning's example uses a 16,384 reasoning budget. This factory enables thinking and caps its own NVIDIA traffic at 30 requests/minute. Provider-side quotas and free endpoint availability can change.

Official model pages:
- https://build.nvidia.com/nvidia/nemotron-3-ultra-550b-a55b/modelcard
- https://build.nvidia.com/nvidia/nemotron-3.5-lightning-30b-a3b/modelcard

## Gemini video review

- Primary: `gemini-3.5-flash-lite`
- Fallback: `gemini-3.1-flash-lite`
- Thinking level: HIGH
- Input: uploaded gameplay video via Gemini Files API

Both official model pages list video/image inputs and thinking support. The helper `tools/gemini_video_review.py` produces a time-stamped visual QA report.

Official pages:
- https://ai.google.dev/gemini-api/docs/models/gemini-3.5-flash-lite
- https://ai.google.dev/gemini-api/docs/models/gemini-3.1-flash-lite
- https://ai.google.dev/gemini-api/docs/video-understanding
- https://ai.google.dev/gemini-api/docs/thinking

## Gemma 4 models

The current official hosted Gemini API guide lists:
- `gemma-4-26b-a4b-it`
- `gemma-4-31b-it`

Google's guide does **not** list a hosted Gemma 4 27B endpoint. The 27B size belongs to Gemma 3. Gemma 4's hosted 26B A4B and 31B models support thinking level HIGH. These models are assigned to text reasoning, not the primary video route.

Official pages:
- https://ai.google.dev/gemma/docs/core/gemma_on_gemini_api
- https://ai.google.dev/gemma/docs/core/model_card_4
- https://ai.google.dev/gemma/docs/capabilities/thinking

## Request limits

Google applies Gemini API limits per Google Cloud project, not per API key. If both keys belong to the same project, they share that project's limits. Limits can also differ by model and usage tier.

The repository uses these **app-side safety ceilings** based on the limits you described:
- NVIDIA: 30 requests/minute across the factory.
- Gemini video models: 10 requests/minute total; up to 500 requests per rolling 24h for the primary model and 500 for the fallback, with a total cap of 1,000.
- Gemma 4: requested app-side ceiling of 28 requests/minute and 14,000 requests per rolling 24h per selected model.

These are local app caps, not confirmation that the providers grant these exact quotas. Check AI Studio's Active Limits for the actual project/model quotas before use. On HTTP 429 or RESOURCE_EXHAUSTED, stop and wait. Never switch keys to bypass a quota.

Official quota guide: https://ai.google.dev/gemini-api/docs/rate-limits

## GitHub Actions Secrets

Create these secret names under Settings -> Secrets and variables -> Actions:
- `NVIDIA_API_KEY`
- `GEMINI_API_KEY_1`
- `GEMINI_API_KEY_2`

Put values only in GitHub Secrets, never in this public repository, issues, logs or source files.
