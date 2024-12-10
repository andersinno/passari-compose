.PHONY: up down start stop restart logs ps build requirements

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

requirements: requirements.txt

%.txt: %.in
	./compile-requirements $<
