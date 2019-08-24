# zabbix-server.sh
PASSWORD="BSAC_PRACTICE_2019"
ZABBIX_SERVER_CONF="/etc/zabbix/zabbix_server.conf"
HTTPD_ZABBIX_CONF="/etc/httpd/conf.d/zabbix.conf"
HTTPD_CONF="/etc/httpd/conf/httpd.conf"

# install and configure MySQL
yum install -y mariadb mariadb-server

/usr/bin/mysql_install_db --user=mysql
systemctl start mariadb

mysql -uroot -e "create database zabbix character set utf8 collate utf8_bin;"
mysql -uroot -e "grant all privileges on zabbix.* to zabbix@localhost identified by '${PASSWORD}';"

# install zabbix server
yum install -y 'http://repo.zabbix.com/zabbix/4.0/rhel/7/x86_64/zabbix-release-4.0-1.el7.noarch.rpm'
yum install -y zabbix-server-mysql zabbix-web-mysql
yum install -y zabbix-agent
yum install -y zabbix-java-gateway

zcat /usr/share/doc/zabbix-server-mysql-*/create.sql.gz | mysql -uzabbix -p${PASSWORD} zabbix

sed -i "/# DBPassword=/a DBPassword=${PASSWORD}" ${ZABBIX_SERVER_CONF}


cat << EOF > /etc/zabbix/web/zabbix.conf.php 
<?php
// Zabbix GUI configuration file.
global \$DB;

\$DB['TYPE']     = 'MYSQL';
\$DB['SERVER']   = 'localhost';
\$DB['PORT']     = '3306';
\$DB['DATABASE'] = 'zabbix';
\$DB['USER']     = 'zabbix';
\$DB['PASSWORD'] = '${PASSWORD}';

// Schema name. Used for IBM DB2 and PostgreSQL.
\$DB['SCHEMA'] = '';

\$ZBX_SERVER      = 'localhost';
\$ZBX_SERVER_PORT = '10051';
\$ZBX_SERVER_NAME = 'Zabbix Server';

\$IMAGE_FORMAT_DEFAULT = IMAGE_FORMAT_PNG;
EOF

# install zabbix agent

# change time zone and address ip-address/zabbix -> ip-address/
sed -i 's/\(\ *\)\(#\ \)\(.*\)Riga$/\1\3Minsk/' ${HTTPD_ZABBIX_CONF}
sed -i 's@\(DocumentRoot \)\"/var/www/html\"@\1"/usr/share/zabbix"@' ${HTTPD_CONF}

# java gateway
sed -i '/# JavaGateway=/a JavaGateway=127.0.0.1' ${ZABBIX_SERVER_CONF}
sed -i '/# StartJavaPollers=/a StartJavaPollers=5' ${ZABBIX_SERVER_CONF}


systemctl start httpd
systemctl start zabbix-server
systemctl start zabbix-agent
systemctl start zabbix-java-gateway
