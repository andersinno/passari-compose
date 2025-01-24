.PHONY: \
	up down start stop restart logs ps build \
	clean-wheels wheels ansible-wheels copy-wheels-to-ansible \
	ansible-requirements requirements

# Destination directories for the ansible-wheels
ANSIBLE_ROLES = ansible/roles
DESTDIR_ANSISBLE_PACKAGES = $(ANSIBLE_ROLES)/passari_packages/files
DESTDIR_ANSISBLE_WHEELS = $(DESTDIR_ANSISBLE_PACKAGES)/wheels

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

ansible-wheels: clean-wheels wheels copy-wheels-to-ansible

copy-wheels-to-ansible:
	rm -fr $(DESTDIR_ANSISBLE_WHEELS)
	mkdir -p $(DESTDIR_ANSISBLE_WHEELS)
	cp -vf wheels/*.whl $(DESTDIR_ANSISBLE_WHEELS)/

ansible-requirements: requirements.txt requirements-siptools.txt
	rm -f $(DESTDIR_ANSISBLE_PACKAGES)/requirements*.txt
	cp -vf requirements.txt requirements-siptools.txt \
		$(DESTDIR_ANSISBLE_PACKAGES)/
	./compile-requirements --hashes \
		$(DESTDIR_ANSISBLE_PACKAGES)/requirements-workflow.in
	./compile-requirements --hashes \
		$(DESTDIR_ANSISBLE_PACKAGES)/requirements-web-ui.in

requirements: requirements.txt requirements-siptools.txt requirements-dev.txt

%.txt: %.in
	./compile-requirements $<
