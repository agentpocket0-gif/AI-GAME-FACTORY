#!/usr/bin/env bash
set -euo pipefail

APK_PATH="${1:-}"
OUT_DIR="${2:-./rea-output}"

if [[ -z "$APK_PATH" || ! -f "$APK_PATH" ]]; then
  echo "Usage: bash tools/rea/analyze-apk.sh /path/to/authorized-app.apk [output-folder]" >&2
  exit 2
fi

if ! command -v rea >/dev/null 2>&1; then
  echo "REA CLI is not installed. Follow docs/APP_ANALYSIS_STACK.md first." >&2
  exit 3
fi

if ! command -v java >/dev/null 2>&1; then
  echo "Java is missing. REA Android analysis needs a full JDK 17+." >&2
  exit 4
fi

if [[ -z "${REA_JADX_MCP_JAR:-}" || ! -f "$REA_JADX_MCP_JAR" ]]; then
  echo "REA_JADX_MCP_JAR must point to the verified JADX 0.7.1 JAR." >&2
  exit 5
fi

mkdir -p "$OUT_DIR"
APK_HASH="$(sha256sum "$APK_PATH" | awk '{print $1}')"
printf 'APK_SHA256=%s\n' "$APK_HASH" | tee "$OUT_DIR/apk-integrity.txt"
printf 'APK_PATH=%s\n' "$APK_PATH" >> "$OUT_DIR/apk-integrity.txt"

# Static package inspection only. This does not run the app or reveal server-side behaviour.
rea inspect-android-package "$APK_PATH" > "$OUT_DIR/android-package-report.txt"

echo "REA package report saved to $OUT_DIR/android-package-report.txt"
echo "Keep this report and the APK out of the public repository if they contain proprietary or private information."
