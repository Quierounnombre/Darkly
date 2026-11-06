#!/bin/sh

#HOW TO OBTAIN A USER
#Note: you can do it with any user range
#curl -X POST "http://localhost:8090/api/collections/users/records" -H "Content-Type: application/json" -d '{"email":"god@test.com","password":"Password123!","passwordConfirm":"Password123!", "role":"god"}'

curl -X POST "http://localhost:8090/api/collections/users/auth-with-password" \
  -H "Content-Type: application/json" \
  -d '{"identity":"god@test.com","password":"Password123!"}' > token.raw

#JUST COSMETIC
jq --tab . token.raw > token.json

my_token=$(jq -r '.token' token.json)

curl -H "Authorization: $my_token" "http://localhost:8090/api/collections/grades/records"
