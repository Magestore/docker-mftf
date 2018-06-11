# Docker MFTF
Docker images for Magento Functional Testing Framework (MFTF)

## Build Images
```sh
rm -rf db/mysql
docker-compose -f docker-compose.yml -f docker-compose.build.yml build
docker-compose -f docker-compose.yml -f docker-compose.build.yml up
sudo docker-compose build
```

## Run Services
```sh
docker-compose up -d
```

## SSH
```sh
docker exec -u {username} -it {container_name} /bin/bash
```

## VNC Viewer
```sh
vncviewer localhost:5900
```
Password: `secret`

## Magento Site
[https://localhost.com/admin/](https://localhost.com/admin/)
admin/admin123
