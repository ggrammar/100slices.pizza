## Gathering Network Interface Facts with Ansible

> Heads up! The code examples in this article use fancy curly brackets `⦃` and `⦄`, instead 
of curly brackets that would actually compile, `{` and `}`. If I use the normal curly brackets,
GitHub Pages tries to render them, and all of my wonderful code examples disappear! 

Let's say you're running a database. It's 2021, and graph databases are popular, so let's say
it's ArangoDB. The database is storing all of your most sensitive... graphs... so you want it
to bind to a private IP address. 

```
# arangod.conf
server.endpoint = tcp://10.0.0.1:8529
```

This works for one server. For the sake of the article, let's say you're running many servers,
and managing them with Ansible. The configuration file should be a template that can apply to many
different servers. Ansible gathers facts about the host it's running on at runtime, so we can do
something like this:

```
# arangod.conf.template
server.endpoint = tcp://⦃⦃ hostvars[inventory_hostname]['ansible_eth0']['ipv4']['address'] ⦄⦄:8529
```

...and Ansible will replace that bracketed block with the IP address of the server it's running on.

This is fine if you know that every server you'll ever touch has an eth0 interface, and that eth0
interface will always have a private IP address. Things aren't usually that simple - what I'd really
like is to use a variable like `private_network_address` and use that instead. 

Ansible gathers all of the information we need to synthesize this variable, it's just a matter of 
putting it together:

```
# arangod.conf.template
⦃# ansible_interfaces is a list of the names of all the network interfaces for this server #⦄
⦃% for iface in hostvars[inventory_hostname]['ansible_interfaces'] %⦄

  ⦃# make sure this interface actually has an ipv4 address #⦄
  ⦃% if hostvars[inventory_hostname]['ansible_' + iface]['ipv4'] is defined %⦄
  
    ⦃# if the interface has a private address, that's a bingo! #⦄
    ⦃% if hostvars[inventory_hostname]['ansible_' + iface]['ipv4']['address'] | ansible.netcommon.ipaddr('private') %⦄
      ⦃% set private_network_address = hostvars[inventory_hostname]['ansible_' + iface]['ipv4']['address'] %⦄
    ⦃% endif %⦄
    
  ⦃% endif %⦄

⦃% endfor %⦄
server.endpoint = tcp://⦃⦃ private_network_address ⦄⦄:8529
```

What a mess! There's all of this _infrastructure_ in my config file, when all I wanted was
the private IP address for the server. Plus, I have to do this separately in every template - 
that's going to make them way bigger than they need to be. 

TODO: I didn't realize at the time of writing that `ansible_all_ipv4_addresses` was a thing. 
Synthesized facts is still a useful pattern. 

## Options
Ideally, I'd like to add functionality to the ansible `setup` module, which is responsible
for gathering facts in the first place. Doesn't seem to be an option.

I could store stuff in `/etc/ansible/facts.d/*.fact`. I don't want to have to manage that.
We're already gathering the information, it just needs to be massaged.

Create a role, `synthetic-facts`, that does this work for us. We'll need to add it to 
every role, so:
```
- hosts: graph-database-servers
  roles:
    - synthetic-facts
    - graph-database
    
- hosts: loadbalancers
  roles:
    - synthetic-facts
    - graph-database
```

I don't really like this either - it's messy to specify the same thing over and over again.
