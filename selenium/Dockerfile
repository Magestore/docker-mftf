FROM selenium/standalone-chrome-debug
# Update chrome
RUN sudo sh -c 'echo "deb http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list' \
    && sudo apt-get update \
    && sudo apt-get --only-upgrade install google-chrome-stable \
    && sudo rm /etc/apt/sources.list.d/google-chrome.list \
    && sudo /opt/bin/wrap_chrome_binary

# Install CA
RUN sudo apt-get update && sudo apt-get install -y libnss3-tools \
    && sudo apt-get clean \
    && sudo rm -rf /var/lib/apt/lists/* /var/cache/apt/*

COPY rootCA.pem rootCA.pem

RUN [ -d ~/.pki/nssdb ] || mkdir -p ~/.pki/nssdb
RUN certutil -d sql:$HOME/.pki/nssdb -N
RUN certutil -d sql:$HOME/.pki/nssdb -A -n 'rootCA' -i rootCA.pem -t TCP,TCP,TCP
