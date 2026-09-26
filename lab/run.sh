#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
export COMPOSE_PROJECT_NAME=opencart-reward-free-checkout
BASE="${1:-http://127.0.0.1:18108}"
chmod +x setup-opencart.sh
if [ ! -f www/index.php ]; then
  echo "Place OpenCart 4.1.0.4 upload/ at ./www (https://github.com/opencart/opencart tag 4.1.0.4)"
  exit 1
fi
if [ -f poc.py ]; then
  POC=./poc.py
elif [ -f ../opencart-reward-free-checkout-Abraxas-Labs.py ]; then
  POC=../opencart-reward-free-checkout-Abraxas-Labs.py
else
  echo "FAIL no poc.py"
  exit 1
fi
chmod +x "$POC" setup-opencart.sh

echo "== docker compose up (OpenCart 4.1.0.4, loopback) =="
docker compose up -d --build

echo "== wait for catalog =="
ok=0
for i in $(seq 1 90); do
  code="$(curl -s -o /tmp/ocbody -w '%{http_code}' --max-time 8 "$BASE/" || true)"
  if [[ "$code" == "200" ]] && grep -qiE 'opencart|common/home|featured|Your Store' /tmp/ocbody 2>/dev/null; then
    echo "IOC opencart-up http=$code"
    ok=1
    break
  fi
  echo "IOC wait i=$i http=$code"
  sleep 5
done
if [[ "$ok" != 1 ]]; then
  echo "FAIL OpenCart did not become ready on $BASE"
  docker compose logs --tail=80 opencart
  exit 1
fi

echo "== poc.py =="
python3 "$POC" "$BASE"
