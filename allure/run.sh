#!/bin/bash

chmod -Rf 777 /allure-results

while true; do
  if [ "$(ls -A /allure-results)" ]; then
    allure report generate /allure-results -o /allure-report
    rm -rf /allure-results/*
  fi
  sleep 1
done
