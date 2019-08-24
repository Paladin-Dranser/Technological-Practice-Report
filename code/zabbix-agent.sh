# zabbix-agent.sh
ZABBIX_AGENTD_CONF="/etc/zabbix/zabbix_agentd.conf"
TOMCAT_FOLDER="/usr/share/tomcat"

# install zabbix agent
yum install -y "http://repo.zabbix.com/zabbix/4.0/rhel/7/x86_64/zabbix-release-4.0-1.el7.noarch.rpm"
yum install -y zabbix-agent

sed -i 's/\(Server=\)127\.0\.0\.1/\1172.31.31.254/' ${ZABBIX_AGENTD_CONF}
sed -i 's/\(ServerActive=\)127\.0\.0\.1/\1172.31.31.254/' ${ZABBIX_AGENTD_CONF}

# nginx + tomcat
yum install -y nginx tomcat

cat <<EOF > /etc/nginx/conf.d/tomcat-upstream.conf
upstream tomcat {
    server 127.0.0.1:8080;
}
EOF

sed -i 's/.*\[::\]:80.*/# \0/' /etc/nginx/nginx.conf
sed -i 's@^\ \+location \/ {@\0\n\t    proxy_pass http://tomcat;@' /etc/nginx/nginx.conf


wget https://tomcat.apache.org/tomcat-7.0-doc/appdev/sample/sample.war -P ${TOMCAT_FOLDER}/webapps/

wget http://ftp.byfly.by/pub/apache.org/tomcat/tomcat-7/v7.0.94/bin/extras/catalina-jmx-remote.jar \
    -P ${TOMCAT_FOLDER}/lib/

sed -i 's@<Listener className="org.apache.catalina.core.ThreadLocalLeakPreventionListener"/>@\0\n
        <Listener className="org.apache.catalina.mbeans.JmxRemoteLifecycleListener"
        rmiRegistryPortPlatform="8097" rmiServerPortPlatform="8098" />@'
        ${TOMCAT_FOLDER}/conf/server.xml

cat << EOF >> /etc/tomcat/tomcat.conf 

JAVA_OPTS="-Djava.rmi.server.hostname=172.31.31.100 \
           -Dcom.sun.management.jmxremote \
           -Dcom.sun.management.jmxremote.local.only=false \
           -Dcom.sun.management.jmxremote.port=12345 \
           -Dcom.sun.management.jmxremote.rmi.port=12346 \
           -Dcom.sun.management.jmxremote.authenticate=false \
           -Dcom.sun.management.jmxremote.ssl=false"
EOF

# start services
systemctl start tomcat
systemctl start nginx
systemctl start zabbix-agent

# for python script
yum install -y python-requests python-netifaces
cp /vagrant/Task\ 3/zabbix-api.py /home/vagrant/

# register host
python /home/vagrant/zabbix-api.py
