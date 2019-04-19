ansible-playbook \
	--inventory='./infra/hosts.yml' \
	--limit='prod' \
	./infra/main.yml
