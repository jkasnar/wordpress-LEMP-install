# wordpress-LEMP-install
This script will help you set up a WordPress site really quick and easy.
The script updates your system, installs and configures Nginx, installs MariaDB and php7.2, and then set up WordPress
installation for the site.

Firstly, the script asks you if you would like to set up a site on a domain name or an IP address.
After that, you provide the script with a database name, database username and database username password that you
would like to set up for your WordPress installation.

After that info is provided, the script will set the needed services and settings.

If you decide to set the site on an IP address, the site's document root will be Nginx's default /usr/share/nginx/html.
If you choose a domain name then the document root of the site will be in /var/www/$DOMAIN_NAME2/html.


