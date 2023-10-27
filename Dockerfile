FROM bitnami/minideb

RUN apt-get update && apt-get install -y curl xz-utils gcc openssl ca-certificates git libpcre++-dev

WORKDIR /root/
RUN curl https://nim-lang.org/choosenim/init.sh -sSf | bash -s -- -y
ENV PATH=/root/.nimble/bin:$PATH

RUN apt -y autoremove
RUN apt -y autoclean
RUN apt -y clean
RUN rm -r /tmp/*

RUN choosenim devel

WORKDIR /usr/src/app

COPY . /usr/src/app
RUN git config --global safe.directory '*'
RUN apt-get install -y sqlite3 postgresql-client
RUN nimble install -y