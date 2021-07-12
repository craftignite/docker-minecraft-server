#!/bin/bash
git checkout master
docker build --tag twometer/craftignite-minecraft:latest .
docker push twometer/craftignite-minecraft:latest

git checkout java8
docker build --tag twometer/craftignite-minecraft:java8 .
docker push twometer/craftignite-minecraft:java8

git checkout java16
docker build --tag twometer/craftignite-minecraft:java16 .
docker push twometer/craftignite-minecraft:java16

git checkout master

echo done :3

