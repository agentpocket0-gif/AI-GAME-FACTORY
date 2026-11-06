# Gemini gameplay video review

This tool analyses a private MP4/MOV/WEBM recording of our own game and writes a timestamped UX/gameplay defect report.

Models:
- Primary: `gemini-3.5-flash-lite`
- Fallback: `gemini-3.1-flash-lite`
- Thinking: HIGH
- Upload: Gemini Files API

Run:

    python -m pip install -r requirements.txt
    python tools/gemini_video_review.py /path/to/our-gameplay.mp4

Two API keys from distinct projects can be used as independent quota pools. Confirm the keys belong to different Google Cloud projects in AI Studio, then set `GEMINI_PROJECTS_ARE_SEPARATE=true` in the runtime environment. The helper round-robins separate new tasks; it does not retry another key after HTTP 429. The video fallback model uses the same selected project.

Per-project app-side limits from the user's reported quotas: 10 RPM total, 500 RPD for each Flash-Lite model and 1,000 total RPD. Two distinct projects therefore have an app-side ceiling of 20 RPM and 2,000 requests/24h. Actual provider quotas may be lower and should be verified in AI Studio.

Private gameplay videos must not be committed to the public repo. Keep files in a private runtime.
