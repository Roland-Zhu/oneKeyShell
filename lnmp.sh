#!/bin/sh
if [ ! $USER = root];then
	echo "Please rerun this script as root"
	exit 1
fi
unaslias cp
cp include/my.cnf /etc/my.cnf
cp include/nginx /etc/init.d/nginx


nginx="http://nginx.org/download/nginx-1.6.2.tar.gz"
mysql="http://cdn.mysql.com/Downloads/MySQL-5.6/mysql-5.6.21.tar.gz"
php="http://hk2.php.net/distributions/php-5.5.17.tar.gz"
libmcrypt="http://nchc.dl.sourceforge.net/project/mcrypt/Libmcrypt/2.5.8/libmcrypt-2.5.8.tar.gz"

mkdir -p /tmp/download
cd /tmp/download
wget $nginx
wget $mysql
wget $php
wget $libmcrypt

tar zxf nginx-1.6.2.tar.gz
tar zxf mysql-5.6.21.tar.gz
tar zxf php-5.5.17.tar.gz
tar zxf libmcrypt-2.5.8.tar.gz

#安装开发工具包
yum -y groupinstall "Development Tools"
#编译安装nginx
cd /tmp/download/nginx-1.6.2
yum install -y pcre pcre-devel zlib* zlib-devel
./configure --prefix=/usr/local/nginx
make && make install

#编译安装mysql
cd /tmp/download/mysql-5.6.21
yum install -y  ncurses-devel cmake
groupadd mysql
useradd -g mysql mysql
cmake  -DCMAKE_INSTALL_PREFIX=/usr/local/mysql -DSYSCONFDIR=/etc -DMYSQL_UNIX_ADDR=/tmp/mysql.sock -DDEFAULT_CHARSET=utf8 -DDEFAULT_COLLATION=utf8_general_ci
make && make install
#新建数据目录
mkdir -p /data/mysql
chown -R mysql:mysql /data/mysql
cd /usr/local/mysql
./scripts/mysql_install_db --user=mysql --basedir=/usr/local/mysql --datadir=/data/mysql 
cp ./support-files/mysql.server /etc/init.d/mysql


#编译安装php
#先安libmcrypt
cd /tmp/download/libmcrypt-2.5.8/
./configure
make && make install
cd /tmp/download/php-5.5.17
cp ./php.ini-development /etc/php.ini
yum install -y libxml2-devel libjpeg-devel libpng-devel freetype-devel openssl-devel libcurl-devel
./configure --prefix=/usr/local/php --with-config-file-path=/etc --with-mysql=/usr/local/mysql -with-mysqli=/usr/local/mysql/bin/mysql_config --with-pdo-mysql --with-mysql-sock=/tmp/mysql.sock --with-gd --with-iconv --with-zlib --enable-xml --enable-bcmath --enable-shmop --enable-sysvsem --enable-inline-optimization --enable-mbregex --enable-fpm --enable-mbstring --with-mcrypt --enable-ftp  --with-gd --with-openssl --with-mhash --enable-pcntl --enable-sockets --with-xmlrpc --enable-zip --enable-soap --with-gettext --with-openssl --enable-pcntl --enable-session
make && make install
cp ./sapi/fpm/init.d.php-fpm /etc/init.d/php-fpm
chmod +x /etc/init.d/php-fpm
cp /usr/local/php/etc/php-fpm.conf.default /usr/local/php/etc/php-fpm.conf

cd /tmp/run
chmod +x /etc/init.d/nginx

service nginx start
service php-fpm start
service mysql start
