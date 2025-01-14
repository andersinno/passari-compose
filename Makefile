.PHONY: \
	up down start stop restart logs ps build \
	clean-wheels wheels ansible-wheels copy-wheels-to-ansible \
	requirements

# Destination directories for the ansible-wheels
ANS_ROLES = ansible/roles
DESTDIR_ANS_WHEELS_BASE = $(ANS_ROLES)/passari_workflow/files/
DESTDIR_ANS_WHEELS_WEB = $(ANS_ROLES)/passari_web_ui/files/

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
	docker-compose up -d web
	docker-compose exec web ./build-wheels

ansible-wheels: clean-wheels wheels copy-wheels-to-ansible

copy-wheels-to-ansible:
	cp -vf wheels/passari-*.whl $(DESTDIR_ANS_WHEELS_BASE)
	cp -vf wheels/passari_workflow-*.whl $(DESTDIR_ANS_WHEELS_BASE)
	cp -vf wheels/passari_web_ui-*.whl $(DESTDIR_ANS_WHEELS_WEB)

requirements: requirements.txt requirements-siptools.txt requirements-dev.txt

%.txt: %.in
	./compile-requirements $<
