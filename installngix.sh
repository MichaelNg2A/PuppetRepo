#/bin/bash
for HOST in $* ; do
ssh -o StrictHostKeyChecking=no $HOST "rpm -qa | egrep -i nginx" 2>&1 >/dev/null
if [ $? -eq 0 ] ; then
		echo "Nginx is already installed on $HOST"
	else
		ssh $HOST "yum --assumeyes install nginx"
fi

ssh $HOST "egrep -v ^# /etc/nginx/conf.d/default.conf | egrep -i listen | egrep default_server | egrep ' 8000 '" 2>&1 >/dev/null
if [ $? -eq 0 ] ; then
                echo "Nginx on $HOST is already listening on port 8000"
        else
		ssh $HOST "sed -i '0,/listen       80 /s//listen       8000 /' /etc/nginx/conf.d/default.conf"
		echo "/etc/nginx/conf.d/default.conf has been updated on $HOST"
fi

ssh $HOST "rpm -qa | egrep -i ^git" 2>&1 >/dev/null
if [ $? -eq 0 ] ; then
		echo "git is already installed on $HOST"
	else
		ssh $HOST "yum --assumeyes install git"
fi

ssh $HOST "git clone https://github.com/puppetlabs/exercise-webpage"
ssh $HOST "mv /usr/share/nginx/html/index.html /usr/share/nginx/html/index.html.orig"
ssh $HOST "cp exercise-webpage/index.html /usr/share/nginx/html/index.html"
ssh $HOST "chcon -R --reference=/usr/share/nginx/html/index.html.orig /usr/share/nginx/html/index.html"
ssh $HOST "rm -R exercise-webpage"

ssh $HOST "chkconfig nginx on"

ssh $HOST "service nginx start"

ssh $HOST "yum --assumeyes install lynx"
done
