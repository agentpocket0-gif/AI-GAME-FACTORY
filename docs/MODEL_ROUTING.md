# Model routing and rate-limit policy

Updated: 2026-11-06

## NVIDIA coding models

- `nvidia/nemotron-3-ultra-550b-a55b`: deep architecture reasoning, complex planning and code review.
- `nvidia/nemotron-3.5-lightning-30b-a3b`: faster routine coding and repair work.

The correct spelling is Nemotron, not Neutron. NVIDIA's model cards document reasoning/thinking controls. The repair agent sets `enable_thinking=true`; Lightning's published example includes a 16,384-token reasoning budget. This workspace applies a conservative application limit of 30 requests/minute. NVIDIA trial endpoint availability and its actual quota may vary.

Official pages:
- https://build.nvidia.com/nvidia/nemotron-3-ultra-550b-a55b/modelcard
- https://build.nvidia.com/nvidia/nemotron-3.5-lightning-30b-a3b/modelcard

## Gemini models for visual review

- `gemini-3.5-flash-lite`: primary video/image review.
- `gemini-3.1-flash-lite`: fallback video/image review.

Both are documented for image and video input and support thinking. The configuration requests high thinking. They are the visual-review route, not the primary code-generation route.

Official pages:
- https://ai.google.dev/gemini-api/docs/models/gemini-3.5-flash-lite
- https://ai.google.dev/gemini-api/docs/models/gemini-3.1-flash-lite
- https://ai.google.dev/gemini-api/docs/thinking

## Gemma 4 hosted model IDs

The official hosted Gemini API guide lists `gemma-4-26b-a4b-it` and `gemma-4-31b-it`. There is no 27B Gemma 4 endpoint in that guide. The 27B size belongs to Gemma 3; Gemma 4's current large model sizes include 26B A4B and 31B. Google documents high thinking for the hosted Gemma 4 API.

Official pages:
- https://ai.google.dev/gemma/docs/core/model_card_4
- https://ai.google.dev/gemma/docs/core/gemma_on_gemini_api

## Rate-limit safeguards

Google says Gemini API limits are applied per Google Cloud project, not per API key. Two keys from the same project share the same RPM/RPD quota. The factory therefore uses one shared quota pool, not 10 requests/minute per key.

Conservative app-side caps until the exact AI Studio quotas are checked:
- NVIDIA: max 30 requests/minute across the factory.
- Gemini: max 10 requests/minute and 500 requests/day across the configured project.
- One request at a time per provider.
- On HTTP 429 or RESOURCE_EXHAUSTED, stop and wait. Do not switch keys to evade a quota.
- Key 2 is only for authentication/configuration recovery.

Actual limits depend on project, tier and model. Check AI Studio's active limits before changing caps. These are application caps, not a promise from Google or NVIDIA.

Official rate-limit page: https://ai.google.dev/gemini-api/docs/rate-limits

## GitHub Actions secrets

Add only these names in Settings -> Secrets and variables -> Actions:
- `NVIDIA_API_KEY`
- `GEMINI_API_KEY_1`
- `GEMINI_API_KEY_2`

Only the secret names are stored here. Never commit actual keys or print them in logs.
