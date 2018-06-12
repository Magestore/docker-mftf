# Docker MFTF
Docker images for Magento Functional Testing Framework (MFTF)

## Build Images
```sh
sudo rm -rf db/mysql
docker-compose -f docker-compose.yml -f docker-compose.build.yml build
docker-compose -f docker-compose.yml -f docker-compose.build.yml up
sudo docker-compose build
sudo rm -rf db/mysql
```

## Run Services
```sh
docker-compose up -d
```

## SSH
```sh
docker exec -u {username} -it {container_name} /bin/bash
```

## Run Test
After `ssh` to docker container `mftf` with username `www-data`
```sh
docker exec -u www-data -it dockermftf_mftf_1 /bin/bash
cd dev/tests/acceptance
vendor/bin/robo generate:tests
vendor/bin/codecept run
```
[https://devdocs.magento.com/guides/v2.2/magento-functional-testing-framework/release-2/getting-started.html](https://devdocs.magento.com/guides/v2.2/magento-functional-testing-framework/release-2/getting-started.html)

[https://codeception.com/docs/02-GettingStarted](https://codeception.com/docs/02-GettingStarted)

## VNC Viewer
```sh
vncviewer localhost:5900
```
Password: `secret`

## Magento Site
[https://localhost.com/admin/](https://localhost.com/admin/)
admin/admin123
