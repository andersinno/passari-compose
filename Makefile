.PHONY: \
	up down start stop restart logs ps build \
	clean-wheels wheels \
	requirements

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

requirements: requirements.txt requirements-dev.txt

%.txt: %.in
	./compile-requirements $<
