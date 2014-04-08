# VERSION 0.1
# DOCKER-VERSION  0.9.1
# AUTHOR:         Irene Knapp <irene.knapp@icloud.com>
# DESCRIPTION:    Image with PostgreSQL installation, built from source.
# TO_BUILD:       docker build -rm -t postgres .
# TO_RUN:         docker run -p 5432:5432 -v /media/state/postgres:/media/host postgres
#
#   To get started, on the host system, create /media/state/postgres, then:
#
#     docker run -v /media/state/postgres:/media/host postgres /reformat.sh
#
#   The above will DESTROY ALL DATA.
#
#   You will now have the directories "config" and "data".  Edit the three
# files in "config" to taste.  You should create a login user and set up a
# connection method; I won't document that here, because to explain how to do
# so securely would be quite verbose.  The initial superuser is named
# "postgres".

FROM debian-stable

#   This weirdness is to make sure nobody can accidentally run reformat.sh on
# the host system!
ADD schebang.in /schebang.in
ADD reformat.sh.in /reformat.sh.in

RUN cat /schebang.in /reformat.sh.in > /reformat.sh; \
    rm /schebang.in /reformat.sh.in; \
    chmod 755 /reformat.sh; \
    echo deb http://security.debian.org/ wheezy/updates main \
      >> /etc/apt/sources.list; \
    DEBIAN_FRONTEND=noninteractive apt-get update; \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
      bzip2 build-essential libreadline6-dev zlib1g-dev sudo openssl \
      libssl-dev uuid libossp-uuid-dev; \
    wget http://ftp.postgresql.org/pub/source/v9.3.4/postgresql-9.3.4.tar.bz2; \
    tar -jxvf postgresql-9.3.4.tar.bz2; \
    cd postgresql-9.3.4; \
    ./configure --with-openssl --with-ossp-uuid; \
    make; \
    make install; \
    cd ..; \
    rm -rf postgresql-9.3.4; \
    DEBIAN_FRONTEND=noninteractive apt-get purge -y \
      bzip2 build-essential libreadline6-dev zlib1g-dev libssl-dev \
      libossp-uuid-dev; \
    DEBIAN_FRONTEND=noninteractive apt-get autoremove; \
    rm /var/lib/apt/lists/*_*; \
    adduser --system --home /media/host --no-create-home --disabled-password \
      --disabled-login --gecos "PostgreSQL daemon" postgres

EXPOSE 5432

CMD sudo -u postgres /usr/local/pgsql/bin/postgres \
    -D /media/host/data \
    -c config_file=/media/host/config/postgresql.conf \
    -c hba_file=/media/host/config/pg_hba.conf \
    -c ident_file=/media/host/config/pg_ident.conf \
    -h "*"
