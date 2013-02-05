#!/bin/bash
#This script will create vhost and set up all environment
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
APACHE_VHOST="apache-vhost.default.conf"
KNOWN_HOST="known_hosts.default"
AUTHORIZED_KEYS="authorized_keys.default"

function createProject {
	local projectName="$1"
	local domainName="$2"
	local homeDir="/home/$projectName"	

	useradd "$projectName"
	mkdir "$homeDir"
	mkdir "/home/www/$projectName"
	ln -s "/home/www/$projectName" "/home/$projectName/www"
	chown "$projectName:$projectName" "$homeDir" -R

	#Apache vhost
	cp "$DIR/$APACHE_VHOST" "$DIR/$domainName.conf";
	perl -pi -e "s/%DOMAIN%/$domainName/g" "$DIR/$domainName.conf"
	perl -pi -e "s/%PROJECT%/$projectName/g" "$DIR/$domainName.conf"
	mv "$DIR/$domainName.conf" "/etc/apache2/sites-available/"
	ln -s "/etc/apache2/sites-available/$domainName.conf" "/etc/apache2/sites-enabled/"


	#SSH keys etc
	mkdir "$homeDir/.ssh"
	cp "$DIR/$KNOWN_HOST" "$homeDir/.ssh/known_host"
	cp "$DIR/$AUTHORIZED_KEYS" "$homeDir/.ssh/authorized_keys"
	chown "$projectName:$projectName" "$homeDir/.ssh" -R
}

createProject "testing" "test.com"

#echo "Create VirtualHost"
#echo "What will be project name?"
#read projectName
#echo "What will be domain for this project?"
#read domainName
#echo "Project name will be $projectName and domain will be $domainName is it correct? [y]/n"
#read response
#
#if [ "$response" = "y" ]; then
#	createProject $projectName $domainName;
#else
#   echo "Ok, run the script again :)"
#fi