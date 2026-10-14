#!/bin/sh

COOKIE="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJzZjZ3dGp5Y2J5ZXY0YWgiLCJsb2dpbiI6InRoYW5vcyIsInJvbGUiOiJzdHVkZW50IiwiZXhwIjoxNzkyNTk1OTMwfQ.hybWJz_hWnHU1iN3eEoZvA6kUiGB7Xm9Ke8bqJKfqCY"

curl -s -X PATCH http://localhost:4942/api/profile \
	-H "Content-Type: application/json" \
	-b "session=$COOKIE" \
	-d '{"role":"cadet"}'
