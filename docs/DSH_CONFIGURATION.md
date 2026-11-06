# DSH provider configuration

This is an example overlay for the official DSH provider adapter. It is not a complete replacement for a DSH profile. Merge the relevant rows into the existing profile at `$DSH_HOME/profiles/<profile>/cordis.patch.yml`.

## NVIDIA NIM route

The overlay registers two model IDs on one custom OpenAI Chat Completions route:
- Nemotron 3 Ultra 550B for architecture and difficult reasoning.
- Nemotron 3.5 Lightning 30B for routine coding and repair.

It selects high thinking and maps it to NVIDIA's `chat_template_kwargs.enable_thinking`. The model cards show that field for thinking mode. It also sets `force_nonempty_content: true` for the Ultra coding-agent route, as NVIDIA documents for coding agents.

The DSH plugin's custom route uses:
- provider `nvidia-nim`
- `api: openai-completions`
- base URL `https://integrate.api.nvidia.com/v1`
- environment credential `NVIDIA_API_KEY`
- `max_tokens` compatibility and system prompt role compatibility.

The DSH profile exposes High in the model's effort selector. The overlay does not claim that it sends NVIDIA's optional top-level `reasoning_budget` field; DSH's generic thinking-budget field list does not include that exact NVIDIA field.

## REA MCP connection

The optional REA entry runs `rea-agents@6.8.0 mcp` over stdio. It needs Node.js and, for Android APK analysis, a full JDK 17+ plus REA's checksum-verified JADX 0.7.1 JAR. The JAR path in the example is a placeholder and must be changed to the verified absolute path. The DSH host and REA process need to run in the same environment to access the same APK filesystem path.

## Gemini and Gemma

Gemini video analysis is handled by `tools/gemini_video_review.py` through Google's Gemini SDK and Files API. DSH's generic OpenAI chat route is not the configured video-upload path.

Gemma 4 text reasoning is handled by `tools/gemma_reason.py`. The two hosted model IDs are `gemma-4-26b-a4b-it` and `gemma-4-31b-it`, with thinking level HIGH.

## Secrets

Set secrets in the DSH runtime environment or GitHub Actions Secrets:
- `NVIDIA_API_KEY`
- `GEMINI_API_KEY_1`
- `GEMINI_API_KEY_2`

Do not write literal key values into this YAML file. Two Gemini keys in one Google Cloud project share its quota.
