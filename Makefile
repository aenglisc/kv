start:
	docker-compose up -d

start-interactive:
	docker-compose run app iex -S mix

stop:
	docker-compose down

build:
	docker-compose build app

install:
	docker-compose run app mix deps.get

test:
	docker-compose run app mix test

setup: build install

.PHONY: test
