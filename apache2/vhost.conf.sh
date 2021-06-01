#!/bin/bash

cat << EOF > /usr/local/apache2/conf.d/000_${SORMAS_SERVER_URL}.conf
<VirtualHost *:80>
        ServerName ${SORMAS_SERVER_URL}

	RedirectMatch "^(/(?!downloads|keycloak|metrics).*)" https://${SORMAS_SERVER_URL}/sormas-ui\$1
	
        ErrorLog /var/log/apache2/error.log
        LogLevel warn
        LogFormat "%h %l %u %t \"%r\" %>s %b _%D_ \"%{User}i\"  \"%{Connection}i\"  \"%{Referer}i\" \"%{User-agent}i\"" combined_ext
        CustomLog /var/log/apache2/access.log combined_ext

        ProxyRequests Off
        ProxyPreserveHost On
        ProxyPass /sormas-ui http://sormas:6080/sormas-ui connectiontimeout=5 timeout=1800
        ProxyPassReverse /sormas-ui http://sormas:6080/sormas-ui
        ProxyPass /sormas-rest http://sormas:6080/sormas-rest connectiontimeout=5 timeout=1800
        ProxyPassReverse /sormas-rest http://sormas:6080/sormas-rest
        ProxyPass /keycloak http://keycloak:8080/keycloak connectiontimeout=5 timeout=600
        ProxyPassReverse /keycloak http://keycloak:8080/keycloak
        <Location /metrics>
            ProxyPass  http://sormas:6080/metrics connectiontimeout=5 timeout=600
            ProxyPassReverse http://sormas:6080/metrics
            Order deny,allow
            Deny from all
            Allow from ${PROMETHEUS_SERVERS}
        </Location>
        RequestHeader set X-Forwarded-Proto https

        Options -Indexes
        AliasMatch "/downloads/sormas-(.*)" "/var/www/sormas/downloads/sormas-\$1"

        Alias "/downloads" "/var/www/sormas/downloads/"

        <Directory "/var/www/sormas/downloads/">
            Require all granted
            Options +Indexes
        </Directory>

        <IfModule mod_deflate.c>
            AddOutputFilterByType DEFLATE text/plain text/html text/xml
            AddOutputFilterByType DEFLATE text/css text/javascript
            AddOutputFilterByType DEFLATE application/json
            AddOutputFilterByType DEFLATE application/xml application/xhtml+xml
            AddOutputFilterByType DEFLATE application/javascript application/x-javascript
            DeflateCompressionLevel 1
        </IfModule>
</VirtualHost>
EOF
exec $@
