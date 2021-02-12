## 

> :warning: The code examples in this article use fancy curly brackets `⦃` and `⦄`, instead 
of curly brackets that would actually compile, `{` and `}`. If I use the normal curly brackets,
GitHub Pages tries to render them and all my wonderful code examples disappear! 

Let's say you're running a database. You don't want to expose your blockchains to the world, 
so the database should bind to the private network address of the host it's running on:

```
server.endpoint = tcp://10.0.0.1:8529
```

If you're just running the one server, you can check that into your playbook and call it a
day. For the sake of the article, let's say you're running many servers, and managing them
with Ansible. You might determine the server's address based on facts gathered at runtime:

```
server.endpoint = tcp://{{ hostvars[inventory_hostname]['ansible_eth0']['ipv4']['address'] }}:8529
```

I already don't like this - there's information about the name of an interface (`eth0`) in my
configuration file, when all I really want is the IPv4 address. It's bearable. 

This is fine if all of your hosts have an eth0 interface, and if you know that eth0 will 
always be bound to a private interface. 

I don't have that luxury - heterogeneous datacenter. 

```
⦃% for iface in hostvars[inventory_hostname]['ansible_interfaces'] %⦄
  {% if hostvars[inventory_hostname]['ansible_' + iface]['ipv4'] is defined %}
    {% if hostvars[inventory_hostname]['ansible_' + iface]['ipv4']['address'] | ansible.netcommon.ipaddr('private') %}
      brpr set private_network_address = hostvars[inventory_hostname]['ansible_' + iface]['ipv4']['address'] prbr
    {% endif %}
  {% endif %}
⦃% endfor %⦄
server.endpoint = tcp://⦃⦃ private_network_address ⦄⦄:8529
```

What a mess! Plus, I have to do all this iteration work every time I want to access this
private address. 

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
