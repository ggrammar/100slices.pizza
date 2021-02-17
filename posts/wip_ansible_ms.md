## WIP: Ansible for Microservices

Let's say you're operating microservices. It's 2021, and blockchain technology is popular, so let's
say you have `block-service` and `chain-service`. 

It's important that these services are managed similarly. Consider:
```
To start the block-service, switch users to the service account block-service. cd /home/block-service (homedir is /var/lib/block for historical reasons). ./service > /var/log/blk.log. 
To start the chain-service, dot-source the environment file at /etc/chsvc.env. Launch the binary at  Press Ctrl+Z, then run "bg", then run "disown" to send the process to the scheduler. Make sure you're running as the chain-service account, chnsvc! 
```

Versus:
```
To start the block-service, "systemctl start block-service". Logs are sent to /var/log/block-service/log.log, and are rotated daily.
To start the chain-service, "systemctl start chain-service". Logs are sent to /var/log/chain-service/log.log, and are rotated daily.
```

Ansible is a great way to provide a consistent infrastructure platform for your microservices.

We'll create a "meta-service" role, where we can define what a microservice looks like in our environment. 

Then, for each service we want to create, we'll create a symlink to "meta-service". During execution, we'll
be deploying the "block-service" or the "chain-service" role, but it's really the same "meta-service" role.

This lets us use the `{% raw %}{{ role_name }}{% endraw %}` variable to create unique resources for the service,
while the bulk of the infrastructure stays exactly the same. 

TODO: This will really only work on Linux. Options for Windows users? ln -s doesn't work in WSL. 

TODO: You could do this with variables. Why is this better? 

```
ln -s ./meta-service ./block-service
ln -s ./meta-service ./chain-service
```

TODO: I guess {{ role_name }} was introduced in Ansible 2.1. When was that released? 

```
- name: Create user account for service.
  user: 
    name: "{{ role_name }}"
    
- name: Create logging directory for service.
  file:
    state: directory
    path: "/var/log/{{ role_name }}/"
    owner: "{{ role_name }}"
```

TODO: Provide some provision for service alternatives, like if we have some services that need to be 
launched one way, and some services that need to be launched a different way. 

In this way, you can build a consistent infrastructure base 

`systemctl status block-service`. 
