start:
	rm -rf tmp/pids/server.pid
	bin/rails s -b 0.0.0.0

start-dev:
	rm -rf tmp/pids/server.pid
	bin/rails s

install:
	bundle install

setup:
	bundle install

cleanup:
	bin/rails db:drop db:create db:migrate

check: test lint

lint:
	bundle exec rubocop -a

test:
	bin/rails test

.PHONY: test
