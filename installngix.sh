#/bin/bash

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
# Update iptables to allow port 8000/tcp                   #
# inbound and make it persistent across reboots.           #
############################################################
ssh $HOST "iptables -I INPUT -p tcp --dport=8000 -j ACCEPT"
ssh $HOST "service iptables save"
ssh $HOST "service iptables restart"

############################################################
# Check to see if git is installed and install if not.     #
############################################################
ssh $HOST "rpm -qa | egrep -i ^git" 2>&1 >/dev/null
if [ $? -eq 0 ] ; then
		echo "git is already installed on $HOST"
	else
		ssh $HOST "yum --assumeyes install git"
fi

############################################################
# Clone Exercises from PuppetLabs Repo.                    #
############################################################
ssh $HOST "git clone https://github.com/puppetlabs/exercise-webpage"

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

############################################################
# Clean up the Puppet Labs Clone created Directory.        #
############################################################
ssh $HOST "rm -R exercise-webpage"

############################################################
# Make sure Nginx comes up on reboot.                      #
############################################################
ssh $HOST "chkconfig nginx on"

############################################################
# Manually start up Nginx the first time.                  #
############################################################
ssh $HOST "service nginx start"

############################################################
# Temporary install of lynx to verify that page is up.     #
############################################################ 
ssh $HOST "yum --assumeyes install lynx"

done
