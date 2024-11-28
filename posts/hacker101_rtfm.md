# Hacker101 RTFM

https://ctf.hacker101.com/ctf

```
% export BASE_URL='https://b92382ffe276f612169505245b1a76aa.ctf.hacker101.com'
```

We don't get much for starters:

```
% curl ${BASE_URL}
API base located at /api/v1/
% curl ${BASE_URL}/api/v1
["Endpoint not found"]
```

I've been using `dirsearch` (https://github.com/maurosoria/dirsearch) to enumerate endpoints:

```
% python3 dirsearch.py -u ${BASE_URL}

  _|. _ _  _  _  _ _|_    v0.4.3
 (_||| _) (/_(_|| (_| )

Extensions: php, asp, aspx, jsp, html, htm | HTTP method: GET | Threads: 25 | Wordlist size: 12266

Target: https://b92382ffe276f612169505245b1a76aa.ctf.hacker101.com/

[15:15:36] Scanning: 
[15:16:07] 200 -    3KB - /api/v2/swagger.json                              
                                                                             
Task Completed
```

That's something! Off to a good start:

```
% curl --silent ${BASE_URL}/api/v2/swagger.json | jq
{
  "swagger": "2.0",
  "flag": "FLAG",
  "info": {
[...]
```

We get a handful of endpoints:

```
% curl --silent ${BASE_URL}/api/v2/swagger.json | jq '.paths' | grep '^  "'     
  "/api/v2/user": {
  "/api/v2/user/login": {
  "/api/v2/admin/user-list": {
  "/api/v2/user/posts/{id}": {
```

`/api/v2/user` POST endpoint is unauthenticated - that's promising. So is `/api/v2/user/login`, but that requires a username and a password (maybe something to look at later). 

```
% curl -d'username=pizza&password=pizza' ${BASE_URL}/api/v2/user
{"username":"pizza","flag":"FLAG","message":"User created go to \/api\/v2\/user\/login to login"}%
% 
% # Let's start a session as well.
% curl -d'username=pizza&password=pizza' ${BASE_URL}/api/v2/user/login
{"session":"edf12810e48a2bcf2d039b8d31851622"}%
``` 


