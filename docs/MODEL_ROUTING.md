# Gemini two-project quota routing

Updated: 2026-11-06

The user has two Gemini API keys from different Google accounts. This repo now supports two independent project pools:

- `GEMINI_API_KEY_1` -> project pool 1
- `GEMINI_API_KEY_2` -> project pool 2

Google documents Gemini limits per Google Cloud project, not per API key. Different account identities do not prove different project IDs by themselves. Before enabling the combined quota, check that each key belongs to a different Google Cloud project in AI Studio. If both keys are from the same project, they share quota and must be treated as one pool.

Set this environment variable only after confirming separate projects:

    GEMINI_PROJECTS_ARE_SEPARATE=true

## App-side caps per project (based on the user's reported active limits)

Flash-Lite video inspection:
- 10 RPM total across the two Flash-Lite models
- 500 requests/rolling 24h on Gemini 3.5 Flash-Lite
- 500 requests/rolling 24h on Gemini 3.1 Flash-Lite
- 1,000 requests/rolling 24h total across these two models

Across two distinct projects, app-side combined ceiling:
- 20 RPM
- 2,000 requests/rolling 24h across Flash-Lite

Gemma 4 text reasoning:
- 28 RPM shared across both Gemma 4 models
- 14,000 requests/rolling 24h shared across both Gemma 4 models

Across two distinct projects, app-side combined ceiling:
- 56 RPM
- 28,000 requests/rolling 24h across Gemma 4

These are app-side caps copied from the user's reported AI Studio quota, not provider guarantees. Real limits can be lower and vary by model, usage tier and project. Google also measures token-per-minute limits, which this request counter cannot fully enforce.

## Pool selection and safety

The helper round-robins **new tasks** across the two configured project pools and maintains a local, locked rolling-24h request ledger. It does not retry the other account after a provider HTTP 429. This avoids treating a project quota error as an invitation to evade the provider's limit. A later independent task can use the other separately-quotaed project according to the normal round-robin schedule.

## Video inspection

`tools/gemini_video_review.py` uses Gemini 3.5 Flash-Lite first and Gemini 3.1 Flash-Lite only as a same-project fallback for non-quota errors. Both models support video input and high thinking mode in the official model pages. The helper uploads videos through Gemini Files API and saves a timestamped review report.

## Gemma reasoning

`tools/gemma_reason.py` uses either hosted Gemma 4 model with high thinking mode:
- `gemma-4-26b-a4b-it`
- `gemma-4-31b-it`

The hosted Gemini API docs list these model IDs. There is no hosted Gemma 4 27B ID in that list.

## Secrets and environment variables

GitHub Actions Secrets:
- `GEMINI_API_KEY_1`
- `GEMINI_API_KEY_2`

Runtime environment (non-secret switch after verifying projects):
- `GEMINI_PROJECTS_ARE_SEPARATE=true`

Never commit either key. Do not write project IDs or account email addresses into the public repository.
