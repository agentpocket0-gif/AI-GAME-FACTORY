# Gemini gameplay video review

This helper analyses an authorised MP4/MOV/WEBM recording of our own game's screen and saves a UX/gameplay bug report.

## Models

- Primary: gemini-3.5-flash-lite
- Fallback: gemini-3.1-flash-lite
- Thinking level: HIGH
- Video upload: Gemini Files API

Both model IDs support video input and thinking according to Google's model pages. The helper does not use Gemma for video; Gemma 4 is reserved for text/reasoning tasks.

## Run

Install dependencies:

    python -m pip install -r requirements.txt

Set the two keys as environment variables, then run:

    python tools/gemini_video_review.py /path/to/your-gameplay.mp4

Optional output path:

    python tools/gemini_video_review.py /path/to/your-gameplay.mp4 --output reports/video-review/review.md

Do not place private recordings or personal information in this public repository. Run this helper in a private environment with the video file. The helper uses a local quota ledger at .cache/gemini-video-quota.json and applies 10 RPM, 500 requests per 24 hours per configured model, and 1,000 requests total per 24 hours. This is an app-side safety cap; real quotas are displayed in AI Studio.

Two keys from the same Google Cloud project share quotas. The helper stops on 429/RESOURCE_EXHAUSTED and never switches keys to bypass a limit. The second key is not used as an RPM multiplier.
