#!/bin/bash
set -e # Останавливать скрипт при любой ошибке

SERVICE_NAME=$1
RELEASE_VERSION=$2
GITHUB_USER="Gorkyichocolate" # Замени на свой username при необходимости

# Устанавливаем компилятор protoc и Go-плагины
sudo apt-get update && sudo apt-get install -y protobuf-compiler
go install google.golang.org/protobuf/cmd/protoc-gen-go@latest
go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest

# Создаем базовую папку, если её ещё нет
mkdir -p golang

# Генерируем Go-код
protoc -I . \
  --go_out=./golang --go_opt=paths=source_relative \
  --go-grpc_out=./golang --go-grpc_opt=paths=source_relative \
  ./${SERVICE_NAME}/*.proto

# Инициализируем и обновляем Go-модуль
cd golang/${SERVICE_NAME}
go mod init github.com/${GITHUB_USER}/microservices-proto/golang/${SERVICE_NAME} || true
go mod tidy
cd ../../

# Настраиваем git-бота и коммитим сгенерированный код
git config --global user.email "github-actions[bot]@users.noreply.github.com"
git config --global user.name "github-actions[bot]"

git add .
git commit -m "chore(${SERVICE_NAME}): generate proto for ${RELEASE_VERSION}" || true
git push origin HEAD:main

# Вешаем специфичный для Go-подмодулей тег и пушим его
git tag -fa golang/${SERVICE_NAME}/${RELEASE_VERSION} -m "golang/${SERVICE_NAME}/${RELEASE_VERSION}"
git push -f origin refs/tags/golang/${SERVICE_NAME}/${RELEASE_VERSION}