# Gemma 4 text reasoning

This helper uses a hosted Gemma 4 model for planning, analysis and text-only second opinions.

Supported model IDs in the Gemini API:
- `gemma-4-26b-a4b-it`
- `gemma-4-31b-it`

Both are configured with thinking level HIGH. Google does not list a hosted 27B Gemma 4 model; 27B is a Gemma 3 size.

Install dependencies:

    python -m pip install -r requirements.txt

Set `GEMINI_API_KEY_1` in a private runtime and run:

    python tools/gemma_reason.py "Review the current game architecture and identify the highest-risk bugs."

Select the larger model:

    python tools/gemma_reason.py "Review the game plan" --model gemma-4-31b-it

The local quota ledger applies the configured app-side guard of 28 requests/minute and 14,000 requests/24h per model. These are the caps requested for the application, not guarantees from Google. Actual RPM/TPM/RPD quotas are visible in AI Studio and are scoped by project/model. The helper stops when it receives 429/RESOURCE_EXHAUSTED and never switches keys to evade the limit.
