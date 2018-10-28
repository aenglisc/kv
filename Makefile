start:
	docker-compose up -d

stop:
	docker-compose down

build:
	docker-compose build app

install:
	docker-compose run --rm app mix deps.get

start-interactive:
	docker-compose run --rm app iex -S mix

test:
	docker-compose run --rm app mix test

setup: build install

.PHONY: test
