# Hacker101 Hacky Holidays

https://ctf.hacker101.com/ctf/start/44

```bash
export BASE_URL=https://566e329fdf54cd4a229a46cdc8d0fb20.ctf.hacker101.com
```

```
% curl $BASE_URL
<!DOCTYPE html>
<html>
<head>
    <title>Grinch Networks</title>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <link rel="stylesheet" href="assets/css/home.css" crossorigin="anonymous">
</head>
<body>
<video autoplay muted loop id="myVideo">
    <source src="assets/video/snow.mp4" type="video/mp4">
</video>
<div class="content">
    <img src="assets/images/grinch-keepout.png" height="500px">
</div>
</body>
</html>
% curl --fail $BASE_URL/assets/
curl: (56) The requested URL returned error: 403
% curl --fail $BASE_URL/assets/video/
curl: (56) The requested URL returned error: 403
% curl --fail $BASE_URL/assets/images/
curl: (56) The requested URL returned error: 403
% 
```

Let's start `ffuf` looking for other endpoints:

```
% ffuf -w ~/dev/ggordon-sec-tools/words/ffuf/common.txt  -u "${BASE_URL}/FUZZ" 
[...]
assets                  [Status: 301, Size: 178, Words: 6, Lines: 8, Duration: 76ms]
favicon.ico             [Status: 200, Size: 5430, Words: 10, Lines: 4, Duration: 81ms]
forum                   [Status: 302, Size: 0, Words: 1, Lines: 1, Duration: 128ms]
robots.txt              [Status: 200, Size: 120, Words: 4, Lines: 4, Duration: 209ms]
```

Very helpful!

```
% curl ${BASE_URL}/robots.txt
User-agent: *
Disallow: /s3cr3t-ar3a
Flag: ^FLAG^45067379ae35a2f23e47f2ef5ab853918675dfc0863945e3eecc47c64ecf42a6$FLAG$
% curl ${BASE_URL}/forum/ 
# This gets us a new web page. 
% curl ${BASE_URL}/s3cr3t-ar3a/
# This also gets us a new web page. 
```

Re-run `ffuf` on the new endpoints:

```
% ffuf -r -recursion -recursion-depth 5 -w ~/dev/ggordon-sec-tools/words/ffuf/common.txt  -u "${BASE_URL}/forum/FUZZ" 
[...]
2                       [Status: 200, Size: 1882, Words: 512, Lines: 56, Duration: 85ms]
1                       [Status: 200, Size: 2238, Words: 788, Lines: 62, Duration: 111ms]
login                   [Status: 200, Size: 1574, Words: 396, Lines: 34, Duration: 66ms]
phpmyadmin              [Status: 200, Size: 8880, Words: 956, Lines: 79, Duration: 101ms]
%
% ffuf -r -recursion -recursion-depth 5 -w ~/dev/ggordon-sec-tools/words/ffuf/common.txt  -u "${BASE_URL}/s3cr3t-ar3a/FUZZ"
[...]
# No results
%
```

Can we do anything interesting with these login endpoints? Doesn't seem like they're 
vulnerable to SQL injection. I don't see any way to do XSS, either. 

Are we able to make posts somehow? Let's try POST and PUT requests on the forum endpoints.

GET and POST work. OPTIONS, PUT, DELETE, TRACE, PATCH get 405, HEAD gets 404, CONNECT gets 400.

I guess, we already knew that POST works, because we have those login endpoints. 

We can try common usernames and passwords on both login panels, that's a start. Maybe "root"
for the phpmyadmin panel, and "admin" for the forum login panel. 

No luck there, either. Subdomains? `nmap`? 
