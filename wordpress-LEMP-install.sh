#!/bin/bash

echo "Are you setting this site on a domain name or an IP address? [1] domain; [2] IP"
read IP_OR_DOMAIN

# Check if the user wants to set up a site for an IP address or domain name
# and set up needed files and variables
if [ $IP_OR_DOMAIN = "1" ]; then
  echo "Please enter a domain name: "
  read IP_DOMAIN
  mkdir -p /var/www/$IP_DOMAIN/html
  mkdir -p /etc/nginx/sites-available
  mkdir -p /etc/nginx/sites-enabled
  DOCUMENT_ROOT=/var/www/$IP_DOMAIN/html
  NGINX_CONF=/etc/nginx/sites-available/$IP_DOMAIN.conf
elif [ $IP_OR_DOMAIN = "2" ]; then
  echo "Please enter an IP address: "
  read IP_DOMAIN
  DOCUMENT_ROOT=/usr/share/nginx/html
  NGINX_CONF=/etc/nginx/conf.d/default.conf
else
  echo "Invalid input!"
  exit 1
fi

echo "Please enter database name: "
read DATABASE_NAME

echo "Please enter database username: "
read DATABASE_USERNAME

echo "Please enter database username password: "
read DATABASE_USER_PASSWORD

# Update system before installing software
yum makecache
yum update -y

install_nginx()
{
  yum install epel-release -y
  yum install nginx -y
  systemctl start nginx
  systemctl enable nginx

  cat > $NGINX_CONF <<!EOF
server {
   listen       80;
   server_name  $IP_DOMAIN;

   # note that these lines are originally from the "location /" block
   root   $DOCUMENT_ROOT;
   index index.php index.html index.htm;

   location / {
       try_files \$uri \$uri/ =404;
   }
   error_page 404 /404.html;
   error_page 500 502 503 504 /50x.html;
   location = /50x.html {
       root $DOCUMENT_ROOT;
   }

   location ~ \.php\$ {
       try_files \$uri =404;
       fastcgi_pass unix:/var/run/php-fpm/php-fpm.sock;
       fastcgi_index index.php;
       fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
       include fastcgi_params;
   }
}
!EOF

  CONF_FILES=$(ls /etc/nginx/sites-available | wc -l)
  if [ $IP_OR_DOMAIN = "1" ] && [ $CONF_FILES -gt "1" ]; then
    ln -s $NGINX_CONF /etc/nginx/sites-enabled/$IP_DOMAIN.conf
    echo "Nginx is already configured"
  elif [ $IP_OR_DOMAIN = "1" ]; then
    ln -s $NGINX_CONF /etc/nginx/sites-enabled/$IP_DOMAIN.conf
    sed -i '58i include /etc/nginx/sites-enabled/*.conf;' /etc/nginx/nginx.conf
    sed -i '59i server_names_hash_bucket_size 64;' /etc/nginx/nginx.conf
  else
    echo "No need for additional configuration of Nginx."
  fi
}

install_mariadb()
{
   yum install mariadb-server mariadb -y
   systemctl start mariadb
   systemctl enable mariadb
}

install_php()
{
  yum install wget -y
  wget http://rpms.remirepo.net/enterprise/remi-release-7.rpm
  rpm -Uvh remi-release-7.rpm
  yum install yum-utils -y
  yum-config-manager --enable remi-php72 -y
  yum --enablerepo=remi,remi-php72 install php-fpm php-common -y
  yum --enablerepo=remi,remi-php72 install php-opcache php-pecl-apcu php-cli php-pear php-pdo php-mysqlnd php-pgsql php-pecl-mongodb php-pecl-redis php-pecl-memcache php-pecl-memcached php-gd php-mbstring php-mcrypt php-xml -y

  sed -i 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g' /etc/php.ini
  sed -i 's/listen = 127.0.0.1:9000/listen = \/var\/run\/php-fpm\/php-fpm.sock/g' /etc/php-fpm.d/www.conf
  sed -i 's/;listen.group = nobody/listen.group = nginx/g' /etc/php-fpm.d/www.conf
  sed -i 's/;listen.owner = nobody/listen.owner = nginx/g' /etc/php-fpm.d/www.conf
  sed -i 's/user = apache/user = nginx/g' /etc/php-fpm.d/www.conf
  sed -i 's/group = apache/group = nginx/g' /etc/php-fpm.d/www.conf

  systemctl start php-fpm.service
  systemctl enable php-fpm.service
}

wordpress_setup()
{
  wget https://wordpress.org/latest.tar.gz -P $DOCUMENT_ROOT
  tar -xzvf $DOCUMENT_ROOT/latest.tar.gz -C $DOCUMENT_ROOT/
  mv $DOCUMENT_ROOT/wordpress/* $DOCUMENT_ROOT/.
  cp $DOCUMENT_ROOT/wp-config-sample.php $DOCUMENT_ROOT/wp-config.php

  sed -i 's/define('\''DB_NAME'\'', '\''database_name_here'\'');/define('\''DB_NAME'\'', '\''\'$DATABASE_NAME''\'');/g' $DOCUMENT_ROOT/wp-config.php
  sed -i 's/define('\''DB_USER'\'', '\''username_here'\'');/define('\''DB_USER'\'', '\''\'$DATABASE_USERNAME''\'');/g' $DOCUMENT_ROOT/wp-config.php
  sed -i 's/define('\''DB_PASSWORD'\'', '\''password_here'\'');/define('\''DB_PASSWORD'\'', '\''\'$DATABASE_USER_PASSWORD''\'');/g' $DOCUMENT_ROOT/wp-config.php
  sed -i '49,56d;' $DOCUMENT_ROOT/wp-config.php

  SEC_KEYS=$(wget -qO- https://api.wordpress.org/secret-key/1.1/salt/)
  echo "$SEC_KEYS" > /tmp/sec_keys.txt
  sed -i 's/'\''/replace_this/g' /tmp/sec_keys.txt
  sed -i '48r /tmp/sec_keys.txt' $DOCUMENT_ROOT/wp-config.php
  sed -i 's/replace_this/'\''/g' $DOCUMENT_ROOT/wp-config.php

  mysql -e "create database $DATABASE_NAME"
  mysql -e "GRANT ALL PRIVILEGES ON $DATABASE_NAME.* TO "$DATABASE_USERNAME"@"localhost" IDENTIFIED BY '$DATABASE_USER_PASSWORD'"
}

main()
{
  install_nginx
  install_mariadb
  install_php
  wordpress_setup
  systemctl restart nginx

  echo "The installation is finished"
  echo "Please visit http://$IP_DOMAIN to finish setting up a WordPress site"
}
main
