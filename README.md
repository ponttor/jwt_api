[![CI Status](https://github.com/ponttor/jwt_api/actions/workflows/main.yml/badge.svg)](https://github.com/ponttor/jwt_api/actions)

## JWT API

## Technical specifications and requirements for the project

ruby ​​-v => 3.1.1  
rails -v => 7.2.1  

## Local installation

```bash
git clone git@github.com:ponttor/jwt-api.git && \
  cd ./jwt-api && \
  make setup
```

## Starting project

```bash
make start-dev
```

## Refreshing database

```bash
make cleanup
```

## Starting tests and linting code

```bash
make check
```

Or start them separately:

```bash
make lint
```

```bash
make test
```