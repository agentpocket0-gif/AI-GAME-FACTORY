# Gemini gameplay video review

This tool sends a private gameplay recording from your own game to Gemini and saves a time-stamped UX/gameplay report.

Models:
- Primary: `gemini-3.5-flash-lite`
- Fallback: `gemini-3.1-flash-lite`
- Thinking level: HIGH
- Upload: Gemini Files API

Both Google model pages document video and image input plus thinking support. Gemma is not used for video in this helper.

Install the dependency:

    python -m pip install -r requirements.txt

Set `GEMINI_API_KEY_1` in the private runtime, then run:

    python tools/gemini_video_review.py /path/to/gameplay.mp4

Optional output path:

    python tools/gemini_video_review.py /path/to/gameplay.mp4 --output reports/video-review/review.md

Do not commit private gameplay videos or account information to this public repository. The helper maintains a local quota ledger under `.cache/`, uses one request at a time and stops on 429/RESOURCE_EXHAUSTED without trying another key. The second key is retained for manually approved authentication recovery only; it is not a quota multiplier.

The app-side guard caps video review at 10 requests/minute, 500 requests/24h for the primary model and 500 requests/24h for the fallback, with a total 1,000/24h cap. Google applies actual quotas per project and model; check AI Studio for your live limit.
