#!/bin/bash
#This script will create vhost and set up all environment
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
NGINX_VHOST="nginx-vhost.default.conf"
NGINX_VHOST_SSL="nginx-vhost-ssl.default.conf"
KNOWN_HOST="known_hosts.default"
AUTHORIZED_KEYS="authorized_keys.default"
FPM_VHOST="fpm-vhost.default.conf"

function createProject {
	local projectName="$1"
	local domainName="$2"
	local ssl="$3"
	local homeDir="/home/$projectName"	
	local domainDir="/home/www/$projectName/$domainName"

  #Add user and create homedir
  useradd "$projectName"
  mkdir "$homeDir"
  mkdir "/home/www/$projectName"
  mkdir "$domainDir"
  chown "$projectName:$projectName" "/home/www/$projectName" -R
  ln -s "/home/www/$projectName" "/home/$projectName/www"
  chown "$projectName:$projectName" "$homeDir" -R

  #Prepare folders for Webistrano and deployment
  mkdir "$homeDir/temp"
  mkdir "$domainDir/releases"
  mkdir "$domainDir/shared"
  ln -s "$homeDir/temp" "$domainDir/shared/temp"
  mkdir "$domainDir/shared/log"
  mkdir "$domainDir/shared/config"
  chown "$projectName:$projectName" "$domainDir" -R

	#php fpm
	cp "$DIR/$FPM_VHOST" "$DIR/$domainName.conf";
	perl -pi -e "s/%DOMAIN%/$domainName/g" "$DIR/$domainName.conf"
	perl -pi -e "s/%PROJECT%/$projectName/g" "$DIR/$domainName.conf"
	mv "$DIR/$domainName.conf" "/etc/php5/fpm/pool.d/"
	/etc/init.d/php5-fpm restart


	#Nginx vhost
	cp "$DIR/$NGINX_VHOST" "$DIR/$domainName.conf";
	perl -pi -e "s/%DOMAIN%/$domainName/g" "$DIR/$domainName.conf"
	perl -pi -e "s/%PROJECT%/$projectName/g" "$DIR/$domainName.conf"
	mv "$DIR/$domainName.conf" "/etc/nginx/sites-available/"
	ln -s "/etc/nginx/sites-available/$domainName.conf" "/etc/nginx/sites-enabled/"
	mkdir "/var/log/nginx/$domainName"
	/etc/init.d/nginx reload

	if $ssl ; then
		cp "$DIR/$NGINX_VHOST_SSL" "$DIR/$domainName.ssl.conf";
		perl -pi -e "s/%DOMAIN%/$domainName/g" "$DIR/$domainName.ssl.conf"
		perl -pi -e "s/%PROJECT%/$projectName/g" "$DIR/$domainName.ssl.conf"
		mv "$DIR/$domainName.ssl.conf" "/etc/nginx/sites-available/"
		ln -s "/etc/nginx/sites-available/$domainName.ssl.conf" "/etc/nginx/sites-enabled/"
		/etc/init.d/nginx reload    	
	fi

	#SSH keys etc
	mkdir "$homeDir/.ssh"
	cp "$DIR/$KNOWN_HOST" "$homeDir/.ssh/known_hosts"
	cp "$DIR/$AUTHORIZED_KEYS" "$homeDir/.ssh/authorized_keys"
	chown "$projectName:$projectName" "$homeDir/.ssh" -R
}

echo "Create VirtualHost"
echo "What will be project name? It will be also same as username, so don't use spaces and special characters"
read projectName
echo "What will be domain for this project?"
read domainName
echo "Enable SSL? y/[n]"
read ssl
echo "Project name will be $projectName and domain will be $domainName is it correct? [y]/n"
read response

if [ "$response" = "n" ] || [ -z "$response"] ; then
	ssl=false
else
	ssl=true
fi

if [ "$response" = "y" ] || [ -z "$response" ] ; then
	createProject $projectName $domainName $ssl;
	echo "If you didn't see any error its done"
else
	echo "Ok, run the script again :)"
fi
