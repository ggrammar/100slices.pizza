## Synthetic Facts in Ansible

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
{% raw %}
# arangod.conf.template
server.endpoint = tcp://{{ hostvars[inventory_hostname]['ansible_eth0']['ipv4']['address'] }}:8529
{% endraw %}
```

...and Ansible will replace that bracketed block with the IP address of the server it's running on.

This is fine if you know that every server you'll ever touch has an eth0 interface, and that eth0
interface will always have a private IP address. Things aren't usually that simple - maybe one of my 
servers has a bonded pair of NICs on bond0 with the private IP address, or maybe eth0 is the public
interface for just one server. 

What I'd really like is to have a variable like `private_network_address` and use that instead. 

Ansible gathers all of the information we need to synthesize this variable, it's just a matter of 
putting it together. Here's what it looks like in the template:

```
{% raw %}
# arangod.conf.template
{# ansible_interfaces is a list of the names of all the network interfaces for this server #}
{% for iface in hostvars[inventory_hostname]['ansible_interfaces'] %}

  {# make sure this interface actually has an ipv4 address #}
  {% if hostvars[inventory_hostname]['ansible_' + iface]['ipv4'] is defined %}
  
    {# if the interface has a private address, that's a bingo! #}
    {% if hostvars[inventory_hostname]['ansible_' + iface]['ipv4']['address'] | ansible.netcommon.ipaddr('private') %}
      {% set private_network_address = hostvars[inventory_hostname]['ansible_' + iface]['ipv4']['address'] %}
    {% endif %}
    
  {% endif %}

{% endfor %}
server.endpoint = tcp://{{ private_network_address }}:8529
{% endraw %}
```

What a mess! There's all of this _infrastructure_ in my config file, when all I wanted was
the private IP address for the server<sup>[1](#footnote1)</sup>. Plus, I have to do this separately in every template - 
that's going to make the templates way bigger and more complicated than they need to be. 

Ideally, I would have liked to extend the ansible `setup` module, so that it would create 
these facts for me, but I didn't see a low-maintenance way to do that. Instead, I found a
way to create new facts, at runtime, based on the information that `setup` already gathers. 
I'm calling these "synthetic facts". 

## Synthetic Facts

Here's how I create these synthetic facts. I put all of the logic to create these facts in a new 
role, `synthetic-facts`<sup>[2](#footnote2)</sup>. Because the only module that this role calls is `set_fact`, it runs very quickly - 
all of the logic is executed on the controller, using information that `setup` has already gathered
from the host. Here's how the role looks:
```
{% raw %}
# roles/synthetic-facts/tasks/main.yml

- name: Create the "private_network_address" fact. 
  set_fact:
    private_network_address: "{{ hostvars[inventory_hostname]['ansible_' + iface]['ipv4']['address'] }}"
  when: 
    - hostvars[inventory_hostname]['ansible_' + iface]['ipv4']['address'] is defined
    - hostvars[inventory_hostname]['ansible_' + iface]['ipv4']['address'] | ansible.netcommon.ipaddr('private')
  with_items: hostvars[inventory_hostname]['ansible_interfaces']
{% endraw %}
```

And, here's how we might use it in our configuration:
```
{% raw %}
# arangod.conf.template
server.endpoint = tcp://{{ private_network_address }}:8529
{% endraw %}
```

Much cleaner! By separating the logic of finding what our private IP address is from the
actual configuration, we have a cleaner config and a very useful variable. 

The advantage of this pattern is that we can use the synthetic fact in all of our templates. 
Anywhere we want to generically reference a private IP address, we have this variable available. 
You can imagine other synthetic facts that might be useful - a list variable `private_network_addresses`
for hosts connected to multiple private networks, or a `public_network_address` variable.

Here are some other ideas for synthetic facts you might derive from `setup`:
 - `network_interfaces_on_small_subnets`
 - `network_interfaces_without_ipv6_addresses`
 - `disks_over_500GB`
 - `disks_without_partitions`
 - `undefined_environment_variables`

The one drawback to this pattern is that it makes our site.yml a little clumsy. We have to 
add this role to every host/role mapping:
```
# site.yml
- hosts: graph-database-servers
  roles:
    - synthetic-facts
    - graph-database
    
- hosts: loadbalancers
  roles:
    - synthetic-facts
    - loadbalancer
```

In closing - using synthetic facts like this can keep your ansible playbooks very clean,
especially if you're supporting servers in multiple datacenters. 

> <a name="footnote1">1</a> I didn't realize at the time of writing that `ansible_all_ipv4_addresses` 
was available. That solves this specific networking issue, but I think synthetic facts bring much
more to the table. 

> <a name="footnote2">2</a> I considered using `pre_tasks`, but that gets even more repetitive. The role 
offers one place to store all of the logic. I also considered populating `/etc/ansible/facts.d/*.fact` 
on the target server with the required information, but that just feels like I'm managing an agent for an
agentless tool - the role keeps it agentless. 
