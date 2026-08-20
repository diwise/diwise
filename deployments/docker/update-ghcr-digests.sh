#!/usr/bin/env bash
set -euo pipefail

ORG="diwise"
COMPOSE_FILE="${1:-./docker-compose.yaml}"

PACKAGES=(
  "iot-agent"
  "iot-core"
  "iot-device-mgmt"
  "iot-events"
  "iot-transform-fiware"
  "iot-things"
  "diwise-web"
  "context-broker"
)

if [[ ! -f "$COMPOSE_FILE" ]]; then
  echo "Compose-fil hittades inte: $COMPOSE_FILE" >&2
  exit 1
fi

TMP_JSON="$(mktemp)"
trap 'rm -f "$TMP_JSON"' EXIT

python3 - "$TMP_JSON" "$ORG" "${PACKAGES[@]}" <<'PY'
import json
import re
import sys
from urllib.request import urlopen, Request

out_path = sys.argv[1]
org = sys.argv[2]
packages = sys.argv[3:]

results = {}
for pkg in packages:
    url = f"https://github.com/{org}/{pkg}/pkgs/container/{pkg}"
    req = Request(url, headers={"User-Agent": "update-ghcr-digests"})
    with urlopen(req, timeout=30) as resp:
        html = resp.read().decode("utf-8", "replace")

    tag_match = re.search(r'<span class="text-normal h2 mr-1 color-fg-muted" >([^<]+)</span>\s*<span title="Label: Visibility"', html)
    digest_match = re.search(r'value="(sha256:[0-9a-f]{64})"', html)

    if not digest_match:
        raise SystemExit(f"Kunde inte hitta digest för {pkg} på {url}")

    results[pkg] = {
        "tag": tag_match.group(1).strip() if tag_match else "unknown",
        "digest": digest_match.group(1),
        "url": url,
    }

with open(out_path, "w", encoding="utf-8") as f:
    json.dump(results, f, indent=2)
PY

python3 - "$COMPOSE_FILE" "$TMP_JSON" <<'PY'
import json
import re
import sys
from pathlib import Path

compose_path = Path(sys.argv[1])
digests = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))
text = compose_path.read_text(encoding="utf-8")

for pkg, meta in digests.items():
    pattern = rf'(ghcr\.io/diwise/{re.escape(pkg)}@)sha256:[0-9a-f]{{64}}'
    replacement = rf'\1{meta["digest"]}'
    new_text, count = re.subn(pattern, replacement, text)
    if count == 0:
        print(f"Varning: ingen image-rad hittades för {pkg} i {compose_path}", file=sys.stderr)
    else:
        text = new_text
        print(f"Uppdaterade {pkg} -> {meta['digest']} ({meta['tag']})")

compose_path.write_text(text, encoding="utf-8")
PY

echo "Klar: $COMPOSE_FILE"
