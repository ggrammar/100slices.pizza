## Synthetic Facts in Ansible

> Heads up! The code examples in this article use fancy curly brackets `⦃` and `⦄`, instead 
of curly brackets that would actually compile, `{` and `}`. If I use the normal curly brackets,
GitHub Pages tries to render them, and all of my wonderful code examples disappear! 

Let's say you're running a database. It's 2021, and graph databases are popular, so let's say
it's ArangoDB. The database is storing all of your most sensitive... graphs... so you want it
to bind to a private IP address:

```
# arangod.conf
server.endpoint = tcp://10.0.0.1:8529
```

This works for one server - check that config into source control and move on with your day. 

For the sake of the article, let's say you're running many servers, and managing them with Ansible. 
The configuration file should be a template that can apply to many different servers. Ansible gathers
facts about the host it's running on at runtime, so we can do something like this:

```
# arangod.conf.template
server.endpoint = tcp://⦃⦃ hostvars[inventory_hostname]['ansible_eth0']['ipv4']['address'] ⦄⦄:8529
```

...and Ansible will replace that bracketed block with the IP address of the server it's running on.

This is fine if you know that every server you'll ever touch has an eth0 interface, and that eth0
interface will always have a private IP address. Things aren't usually that simple - what I'd really
like is to have a variable like `private_network_address` and use that instead. 

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
that's going to make the templates way bigger than they need to be. 

> I didn't realize at the time of writing that `ansible_all_ipv4_addresses` was available.
That solves this specific issue, but the solution I came up with - synthetic facts - has 
merit beyond this specific problem. 

Ideally, I would have liked to extend the ansible `setup` module, so that it would create 
these facts for me, but I didn't see a low-maintenance way to do that. Instead, I found a
way to create new facts, at runtime, based on the information that `setup` already gathers. 

## Synthetic Facts

Here's how I create additional information on top of the `setup` facts. If we only use `set_fact`, 
this runs very quickly (single-digit seconds), since it's just operating on information we've 
already gathered from the host. I put all of the logic into a role called `synthetic-facts`:
```
# roles/synthetic-facts/tasks/main.yml
- name: Create a list to hold our private IP addresses. 
  set_fact:
    private_addresses: []

- name: Populate the list with private IP addresses. 
  set_fact:
    private_addresses: {{ private_addresses + [ ] }}
  when: 
    - hostvars[inventory_hostname]['ansible_' + iface]['ipv4']['address'] | ansible.netcommon.ipaddr('private')
  with_items: hostvars[inventory_hostname]['ansible_interfaces']
```

We do have to assign this role to every group of hosts. This doesn't really hurt our 
runtime - it's all local, so it's very fast - but it makes our site file a little clumsy:
```
# site.yml
- hosts: graph-database-servers
  roles:
    - synthetic-facts
    - graph-database
    
- hosts: loadbalancers
  roles:
    - synthetic-facts
    - graph-database
```

TODO: Conclusion
