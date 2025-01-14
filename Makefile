.PHONY: \
	up down start stop restart logs ps build \
	clean-wheels wheels \
	ansible-update ansible-wheel-update \
	ansible-requirements requirements

ANSIBLE_DESTDIR ?= ansible/roles/passari_packages/files

up:
	docker-compose up

down:
	docker-compose down

start:
	docker-compose start

stop:
	docker-compose stop

restart:
	docker-compose restart

logs:
	docker-compose logs -f

ps:
	docker-compose ps

build:
	docker-compose build

clean-wheels:
	rm -fr wheels

wheels:
	./build-wheels

ansible-update: clean-wheels wheels ansible-wheel-update ansible-requirements

ansible-wheel-update:
	rm -fr $(ANSIBLE_DESTDIR)/wheels
	mkdir -p $(ANSIBLE_DESTDIR)/wheels
	cp -vf wheels/*.whl $(ANSIBLE_DESTDIR)/wheels/

ansible-requirements: requirements.txt
	rm -f $(ANSIBLE_DESTDIR)/requirements*.txt
	cp -vf requirements.txt $(ANSIBLE_DESTDIR)/
	./compile-requirements --hashes \
		$(ANSIBLE_DESTDIR)/requirements-workflow.in
	./compile-requirements --hashes \
		$(ANSIBLE_DESTDIR)/requirements-web-ui.in

requirements: requirements.txt requirements-dev.txt

%.txt: %.in
	./compile-requirements $<
