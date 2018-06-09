# New SSL style

## Create ROOT CA
```sh
openssl genrsa -des3 -out rootCA.key 2048
openssl req -x509 -new -nodes -key rootCA.key -sha256 -days 3658 -out rootCA.pem
```

## Create SSL
Create file `v3.ext`

```conf
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = x.o
DNS.2 = *.x.o
DNS.3 = localhost
DNS.4 = localhost.com
DNS.5 = *.localhost.com
IP.1 = 127.0.0.1
IP.2 = 192.168.1.5
```

```sh
openssl req -new -nodes -out server.csr -newkey rsa:2048 -keyout server.key
openssl x509 -req -in server.csr -CA rootCA.pem -CAkey rootCA.key -CAcreateserial -out server.crt -days 3658 -sha256 -extfile v3.ext
```

## Add Trusted Certificate
[Install Root Cert](https://www.bounca.org/tutorials/install_root_certificate.html)

OR

```sh
sudo apt-get install libnss3-tools
[ -d ~/.pki/nssdb ] || mkdir -p ~/.pki/nssdb
certutil -d sql:$HOME/.pki/nssdb -A -n 'rootCA' -i rootCA.pem -t TCP,TCP,TCP
```
