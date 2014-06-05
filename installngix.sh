#/bin/bash
############################################################
#                                                          #
# Filename:	installngix.sh                             #
# Author:	Michael Ng                                 #
# Last Update:	06/05/2014                                 #
# Version:	1.0                                        #
#                                                          #
# Usage:	installngix.sh [Host1] [Host2] [...]       #
#                                                          #
# This shell script will take any number of hosts in as    #
# arguments and perform the following tasks as needed:     #
#                                                          #
# 1.) Install nginx server.                                #
# 2.) Change the listening port to 8000/tcp.               #
# 3.) Update iptables to allow 8000/tcp inbound.           #
# 4.) Install git.                                         #
# 5.) Clone https://github.com/puppetlabs/exercise-webpage #
# 6.) Backup the current default index.html file.          #
# 7.) Update the default index.html file.                  #
# 8.) Update file context of new index.html file.          #
# 9.) Configure nginx server to start on system reboot.    #
# 10.) Start nginx server.                                 #
#                                                          #
############################################################
# Gather a list of Hosts to run this script against.       #
############################################################
for HOST in $* ; do

############################################################
# Check to see if nginx is installed and install if not.   #
############################################################
ssh -o StrictHostKeyChecking=no $HOST "rpm -qa | egrep -i nginx" 2>&1 >/dev/null
if [ $? -ne 0 ] ; then
	ssh $HOST "yum --assumeyes install nginx"
fi

############################################################
# Check to see if the default Nginx Config is set to       #
# listen to Port 8000.  Change to port 8000 if necessary.  #
############################################################
ssh $HOST "egrep -v ^# /etc/nginx/conf.d/default.conf | egrep -i listen | egrep default_server | egrep ' 8000 '" 2>&1 >/dev/null
if [ $? -ne 0 ] ; then
	ssh $HOST "sed -i '0,/listen       80 /s//listen       8000 /' /etc/nginx/conf.d/default.conf"
	echo "/etc/nginx/conf.d/default.conf has been updated on $HOST"
fi

############################################################
# Check to see if iptables is configured to allow          #
# port 8000/tcp inbound, update iptables and make it       #
# persistent across reboots if the rule is not there.      #
############################################################
ssh $HOST "iptables-save | egrep -i INPUT | egrep -i tcp | egrep -i 'dport 8000' | egrep -i accept" 2>&1 >/dev/null
if [ $? -ne 0 ] ; then
	ssh $HOST "iptables -I INPUT -p tcp --dport=8000 -j ACCEPT"
	ssh $HOST "service iptables save"
	ssh $HOST "service iptables restart"
fi

############################################################
# Check to see if git is installed and install if not.     #
############################################################
ssh $HOST "rpm -qa | egrep -i ^git" 2>&1 >/dev/null
if [ $? -ne 0 ] ; then
	ssh $HOST "yum --assumeyes install git"
fi

############################################################
# Clone Exercises from PuppetLabs Repo.                    #
############################################################
ssh $HOST "git clone https://github.com/puppetlabs/exercise-webpage"

############################################################
# Check to see if the desired html file is already in      #
# place and backup, copy, change context if not.           #
############################################################
ssh $HOST "diff exercise-webpage/index.html /usr/share/nginx/html/index.html" 2>&1 >/dev/null
if [ $? -ne 0 ] ; then

############################################################
# Rename the original default Nginx index.html file.       #
############################################################
ssh $HOST "mv /usr/share/nginx/html/index.html /usr/share/nginx/html/index.html.orig"

############################################################
# Copy the index.html file from the PuppetLabs clone.      #
############################################################
ssh $HOST "cp exercise-webpage/index.html /usr/share/nginx/html/index.html"

############################################################
# Update file contexts.                                    #
############################################################
ssh $HOST "chcon -R --reference=/usr/share/nginx/html/index.html.orig /usr/share/nginx/html/index.html"

fi

############################################################
# Clean up the Puppet Labs Clone created Directory.        #
############################################################
ssh $HOST "rm -R exercise-webpage"

############################################################
# Check that Nginx is configured to                        #
# start on reboot and correct if necessary.                #
############################################################
ssh $HOST "chkconfig nginx" 2>&1 >/dev/null
if [ $? -ne 0 ] ; then
	ssh $HOST "chkconfig nginx on"
fi

############################################################
# Verify that Nginx is running and start up if not.        #
############################################################
ssh $HOST "service nginx status" 2>&1 >/dev/null
if [ $? -ne 0 ] ; then
	ssh $HOST "service nginx start"
fi

############################################################
# Temporary install of lynx to verify that page is up.     #
############################################################ 
ssh $HOST "yum --assumeyes install lynx"

done
