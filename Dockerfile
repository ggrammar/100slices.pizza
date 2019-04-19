FROM ubuntu

RUN apt-get update 

RUN apt-get install -y \
	openssh-server \
	python3

# TODO: Use someone other than root. 
# Prepare the container to use Ansible. 
RUN mkdir /root/.ssh/

COPY id_rsa.pub /root/.ssh/authorized_keys

RUN chown root:root /root/.ssh/authorized_keys

CMD /usr/sbin/service ssh start && tail -F /var/log/faillog

