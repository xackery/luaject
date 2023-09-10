NAME := yakuku
SHELL := /bin/bash
VERSION ?= 0.0.4

run-sql-%:
	make build
	mkdir -p bin/out
	cd bin && ./${NAME} sql $* $*.yaml out/$*.sql	

run-inject-%:
	make build
	mkdir -p bin/out
	cd bin && ./${NAME} inject out/$*.sql

run-yaml-%:
	make build
	mkdir -p bin/out
	@#cd bin && ./${NAME} yaml $* $*.yaml 9979 9990 9991 32601 32601
	cd bin && ./${NAME} yaml $* $*.yaml 56

# compilies the project to bin/
build:
	mkdir -p bin
	go build -o bin/${NAME} main.go
# runs all build commands
build-all: build-linux build-windows
build-linux:
	CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o bin/${NAME} -ldflags="-X main.Version=${VERSION} -s -w" main.go
build-windows:
	CGO_ENABLED=0 GOOS=windows GOARCH=amd64 go build -o bin/${NAME}.exe -ldflags="-X main.Version=${VERSION} -s -w" main.go
dump-item-%:
	cd bin && ./${NAME} import item $*
show-tables: copy-data
	source .env && cd bin && docker run --rm \
	-v ${PWD}:/src \
    imega/mysql-client \
    mysql --host=$$DB_HOST --user=$$DB_USER --password=$$DB_PASS --database=$$DB_NAME \
	--execute='show tables;'
# inject tries to insert the sql files from bin/ to the db
inject: copy-data
	docker run -it --rm \
	-v ${PWD}/bin:/src \
    imega/mysql-client \
	/bin/sh -c 'source /src/.env && mysql --host=$$DB_HOST --user=$$DB_USER --password=$$DB_PASS $$DB_NAME < /src/aa.sql'

# CICD triggers this
set-version-%:
	@echo "VERSION=${VERSION}.$*" >> $$GITHUB_ENV

	