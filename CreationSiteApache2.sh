#!/bin/bash

#Fonctionnement du Script

function usage
{
echo "Script de création de site web sur serveur apache2"
echo -e "Chaques arguments sera expliquer de la façon suivante \nArgument : Utilisation"
echo -e "-h/--help : Aide
-y : Plusieurs virtual hosts
-n : Un seul virtual hosts
--name : Nom du site
--port : Port sur lequel le site fonctionne
--dir : DocumentRoot site (premier si plusieurs virtual hosts)
--dir2 : (optionel) DocumentRoot du deuxieme site
--ip : (optionel) Ip sur laquelle le (premier) site fonctionne (si option y utilisé)
--ip2 : (optionel) Ip sur laquelle le deuxième site fonctionne (si option y utilisé)"
}

#On récupère le premier '-' qui est obligatoire
optspec=":-:"

#On récupère ce qui se trouve après le premier '-'
#La variable OPTIND récupère l'argument après l'option

while getopts "$optspec" optchar; do
case "${OPTARG}" in
  help)
	usage
	exit 1
	;;
  port)
	valeur="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
	port_site=${valeur}
	;;
  dir)
	valeur="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
	docRoot1=${valeur}
	;;
  dir2)
	valeur="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
	docRoot2=${valeur}
	;;		
  ip)
	valeur="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
	ipsite1=${valeur}
	;;
  ip2)
	valeur="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
	ipsite2=${valeur}
	;;
  name)
	valeur="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
	domain_name=${valeur}
	;;
  y)
	restrictyorn="y"
	;;
  n)
	restrictyorn="n"
	;;
  h)
    usage
    exit 1
    ;;
  *)
    exit 1
    ;;
esac
done

#Dernier id utilisé pour le nom du fichier exemple : "030-linux.org" = "030"

dernier_id=`ls /etc/apache2/sites-available/ | sort -nr | head -n1 | cut -d- -f1`
dernier_id=`expr $dernier_id + 1`

#Repertoire sites Apache2

directory_site_e="/etc/apache2/sites-enabled"
directory_site_a="/etc/apache2/sites-available"


#Si on veut plusieurs virtual hosts

if [ $restrictyorn = "y" ];
then

#Vérifie si les éléments suivants on été donnés : nom de domaine, ip de chaques virtual hosts, port du site, documentRoot pour chaques sites

if [ -n $domain_name ] && [ -n $port_site ] && [ -n $ipsite ] && [ -n $docRoot1 ] && [ -n $ipsite2 ] && [ -n $docRoot2 ]
then

#Crée les dossiers spécifiés dans les documentRoot si ils n'existent pas

if [ -d $docRoot1 ]
then
echo "Dossier existant"
else
mkdir -p $docRoot1
fi

if [ -d $docRoot2 ]
then
echo "Dossier existant"
else
mkdir -p $docRoot2
fi

#Création du fichier de conf du site "nom_du_site.conf" avec mise en place des droits sur le DocumentRoot

cat <<EOF >> $directory_site_a/0$dernier_id-$domain_name'.conf'
<VirtualHost $ipsite1:$port_site>

  # Admin email, Server Name (domain name) and any aliases
	ServerAdmin webmaster@$domain_name
	ServerName  $domain_name
	ServerAlias www.$domain_name
	DocumentRoot $docRoot1

  # Index file and Document Root (where the public files are located)

	 <Directory />
                Options FollowSymLinks
                AllowOverride None
        </Directory>

        <Directory $docRoot1>
                Options Indexes FollowSymLinks MultiViews
                AllowOverride None
                Order allow,deny
                allow from all
        </Directory>
  LogLevel warn
  ErrorLog /var/log/apache2/error-mydomainname.com.log
  CustomLog /var/log/apache2/access-mydomainname.com.log combined

</VirtualHost>

<VirtualHost $ipsite2:$port_site>

  # Admin email, Server Name (domain name) and any aliases
	ServerAdmin webmaster@$domain_name
	ServerName  $domain_name
	ServerAlias www.$domain_name
	DocumentRoot $docRoot2

  # Index file and Document Root (where the public files are located)

	 <Directory />
                Options FollowSymLinks
                AllowOverride None
        </Directory>

        <Directory $docRoot2>
                Options Indexes FollowSymLinks MultiViews
                AllowOverride None
                Order allow,deny
                allow from all
        </Directory>
  LogLevel warn
  ErrorLog /var/log/apache2/error-mydomainname.com.log
  CustomLog /var/log/apache2/access-mydomainname.com.log combined

</VirtualHost>

EOF

#Ajout des droits pour les DocumentRoot dans apache2.conf

cat <<EOF >> /etc/apache2/apache2.conf 
<Directory $docRoot1>
	Options Indexes FollowSymLinks
	AllowOverride None
	Require all granted
</Directory>
<Directory $docRoot2>
	Options Indexes FollowSymLinks
	AllowOverride None
	Require all granted
</Directory>

EOF
fi

#Si on ne veut qu'un virtual host

elif [ $restrictyorn = "n" ];
then

#Vérifie si les éléments suivants on été donnés : nom de domaine, ip du site, port du site, documentRoot du site

if [ -n $domain_name ] && [ -n $ipsite ] && [ -n $port_site ] && [ -n $docRoot1 ]
then

#Crée le dossier spécifier dans le documentRoot si il n'existe pas

if [ -d $docRoot1 ]
then
echo "Dossier existant"
else
mkdir -p $docRoot1
fi

#Création du fichier de conf du site "nom_du_site.conf" avec mise en place des droits sur le DocumentRoot

cat <<EOF >> $directory_site_a/00$dernier_id-$domain_name'.conf'
<VirtualHost *:$port_site>

  # Admin email, Server Name (domain name) and any aliases
	ServerAdmin webmaster@$domain_name
	ServerName  $domain_name
	ServerAlias www.$domain_name
	DocumentRoot $docRoot1

  # Index file and Document Root (where the public files are located)

	 <Directory />
                Options FollowSymLinks
                AllowOverride None
        </Directory>

        <Directory $docRoot1>
                Options Indexes FollowSymLinks MultiViews
                AllowOverride None
                Order allow,deny
                allow from all
        </Directory>
  LogLevel warn
  ErrorLog /var/log/apache2/error-mydomainname.com.log
  CustomLog /var/log/apache2/access-mydomainname.com.log combined

</VirtualHost>
EOF

#Ajout des droits sur le DocumentRoot dans apache2.conf

cat <<EOF >> /etc/apache2/apache2.conf 
<Directory $docRoot1>
	Options Indexes FollowSymLinks
	AllowOverride None
	Require all granted
</Directory>
EOF

fi
fi

#Si le port est specifié, verifie si le fichier ports.conf existe

if [ -n $port_site ]
then
if [ -e "/etc/apache2/ports.conf" ]
then
ajoutport=`cat /etc/apache2/ports.conf | grep -w $port_site | awk {'print $2'}`
if [ -n $ajoutport ]
then
echo "Port déja présent"
else

#Si le port n'est pas encore présent, on l'ajoute

cat <<EOF >> /etc/apache2/ports.conf
Listen $port_site
EOF
fi
else

#Si le fichier n'existe pas on crée le fichier ports.conf

cat <<EOF > /etc/apache2/ports.conf
Listen $port_site
<IfModule ssl_module>
        Listen 443
</IfModule>

<IfModule mod_gnutls.c>
        Listen 443
</IfModule>

EOF
fi
fi

#Si le DocumentRoot à été donné, on crée le fichier apache2.conf si il n'existe pas

if [ -n $docRoot1 ]
then
if [ -e "/etc/apache2/apache2.conf" ]
then
echo "Fichier apache2.conf existant"
else

#Conf des droits sur la racine site apache2

cat <<EOF >> $directory_site_e/apache2.conf 
Mutex file:${APACHE_LOCK_DIR} default
PidFile ${APACHE_PID_FILE}
Timeout 300
KeepAlive On
MaxKeepAliveRequests 100
KeepAliveTimeout 5
User ${APACHE_RUN_USER}
Group ${APACHE_RUN_GROUP}
HostnameLookups Off
ErrorLog ${APACHE_LOG_DIR}/error.log
LogLevel warn
IncludeOptional mods-enabled/*.load
IncludeOptional mods-enabled/*.conf
Include ports.conf
<Directory />
	Options FollowSymLinks
	AllowOverride None
	Require all denied
</Directory>
<Directory /usr/share>
	AllowOverride None
	Require all granted
</Directory>
<Directory $docRoot1>
	Options Indexes FollowSymLinks
	AllowOverride None
	Require all granted
</Directory>
<Directory /var/www/>
	Options Indexes FollowSymLinks
	AllowOverride None
	Require all granted
</Directory>
AccessFileName .htaccess
<FilesMatch "^\.ht">
	Require all denied
</FilesMatch>
LogFormat "%v:%p %h %l %u %t \"%r\" %>s %O \"%{Referer}i\" \"%{User-Agent}i\"" vhost_combined
LogFormat "%h %l %u %t \"%r\" %>s %O \"%{Referer}i\" \"%{User-Agent}i\"" combined
LogFormat "%h %l %u %t \"%r\" %>s %O" common
LogFormat "%{Referer}i -> %U" referer
LogFormat "%{User-agent}i" agent
IncludeOptional conf-enabled/*.conf
IncludeOptional sites-enabled/*.conf
Include /etc/phpmyadmin/apache.conf
# vim: syntax=apache ts=4 sw=4 sts=4 sr noet
EOF
fi
fi

#Si le nom de domaine, l'ip du site, le port du site, le DocumentRoot sont donnés en arguments

if [ -n $domain_name ] && [ -n $ipsite ] && [ -n $port_site ] && [ -n $docRoot1 ]
then

#Création du lien symbolique entre fichier de site-available vers site-enabled 

a2ensite 0$dernier_id-$domain_name

#Vérification de la syntax apache2.conf, fichier site (0 si verification OK)

restartornot=`apache2ctl -t | wc -l`

if [ $restartornot = 0 ]
then

#Redémarage du service apache2

/etc/init.d/apache2 restart
fi
fi
