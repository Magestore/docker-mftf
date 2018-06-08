FROM selenium/standalone-chrome

RUN sudo apt-get update && sudo apt-get install -y libnss3-tools \
    && sudo apt-get clean \
    && sudo rm -rf /var/lib/apt/lists/*

COPY rootCA.pem rootCA.pem

RUN [ -d ~/.pki/nssdb ] || mkdir -p ~/.pki/nssdb
RUN certutil -d sql:$HOME/.pki/nssdb -N
RUN certutil -d sql:$HOME/.pki/nssdb -A -n 'rootCA' -i rootCA.pem -t TCP,TCP,TCP
