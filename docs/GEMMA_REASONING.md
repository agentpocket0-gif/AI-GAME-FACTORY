# Gemma 4 high-thinking text reasoning

Run:

    python -m pip install -r requirements.txt
    python tools/gemma_reason.py "Review the game architecture and list the highest-risk defects."
    python tools/gemma_reason.py "Review the game plan" --model gemma-4-31b-it

Hosted Gemini API model IDs:
- `gemma-4-26b-a4b-it`
- `gemma-4-31b-it`

Both use thinking level HIGH. The official API guide does not list a hosted Gemma 4 27B model.

Two independent Google Cloud projects provide separate app-side pools when each API key is tied to a different project. Confirm this in AI Studio and set `GEMINI_PROJECTS_ARE_SEPARATE=true`. The local limiter allows 28 RPM and 14,000 requests/rolling 24h per project across both Gemma models; across two projects the app-side ceiling is 56 RPM / 28,000 per 24h. These are not guarantees from Google. Actual project/model limits and TPM are controlled by Google.

The helper stops on 429/RESOURCE_EXHAUSTED and does not retry the other key.
