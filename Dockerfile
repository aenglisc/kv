FROM bitwalker/alpine-elixir:1.7

RUN apk add --no-cache curl

WORKDIR /app
