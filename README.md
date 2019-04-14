This is the code for 100slices.pizza. 

What do I want out of a website?
	Inexpensive to host.
	Easy to maintain.
	Good project for learning:
		Deploying Ansible to heterogeneous environments.
		Hosting on GCP. 

What are the components?
	Domain name hosting (got 100slices.pizza from GoDaddy)
	Server hosting (using GCP for this)

I updated the A record for 100slices.pizza to point to the public IP address
of my VM. I could do an MX record in the future - it sure would be fun to host
a mail server! - but for now, I'd like to focus on the website.

So, what are my next steps? I want a functioning website, one that I enjoy
tinkering with. I want it to be easily testable, so I don't brick the whole
thing by making a modification to a production server. 

So, let's say:
	Ansible to manage servers.
	Docker container for a test server.
	GCP instance for production.

So I'm deploying to a heterogenous environment (a container locally, and a
VM remotely). That's kind of nice. I'll just have the Dockerfile be the basic
Ubuntu image. 

That in mind, let's divide up the repository:
	Infrastructure code in ./infra.
	Website code in ./site.
