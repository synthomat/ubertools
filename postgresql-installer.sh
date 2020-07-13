#!/bin/sh
PGVERSION="12.3"

echo "Downloading postgresql-$PGVERSION"
wget https://ftp.postgresql.org/pub/source/v$PGVERSION/postgresql-$PGVERSION.tar.gz

echo "extracting..."
tar xzvf postgresql-$PGVERSION.tar.gz

echo "removing archive"
rm postgresql-$PGVERSION.tar.gz

cd postgresql-$PGVERSION

echo "building..."
./configure --prefix=$HOME/opt/postgresql
make
make install

echo "adding env variables to .bash_profile"

echo "
export PATH=$HOME/opt/postgresql/bin/:\$PATH
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$HOME/opt/postgresql/lib
export PGPASSFILE=$HOME/.pgpass
" >> ~/.bash_profile

cd ~
source ~/.bash_profile

echo "generating password and writing into ~/.pgpass"
PASS=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 64 | head -n 1)
echo "#hostname:port:database:username:password (min 64 characters)
*:*:*:$USER:$PASS
" > ~/.pgpass
chmod 0600 ~/.pgpass
echo $PASS > ~/pgpass.temp

echo "initializing database"
initdb --pwfile ~/pgpass.temp --auth=md5 -E UTF8 -D ~/opt/postgresql/data/
rm ~/pgpass.temp

sed -i "/unix_socket_directories/c\unix_socket_directories = '$HOME/tmp'" opt/postgresql/data/postgresql.conf

echo "export PGHOST=localhost
export PGPORT=5432
" >> ~/.bashrc

echo "creating supervisor item"
echo "[program:postgresql]
command=%(ENV_HOME)s/opt/postgresql/bin/postgres -D %(ENV_HOME)s/opt/postgresql/data/
autostart=yes
autorestart=yes
" >> ~/etc/services.d/postgresql.ini


echo "starting..."
supervisorctl reread
supervisorctl update
supervisorctl start postgresql

