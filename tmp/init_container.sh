#!/usr/bin/env bash
set -m # Enable job control

cat >/etc/motd <<EOL 
  _____                               
  /  _  \ __________ _________   ____  
 /  /_\  \\___   /  |  \_  __ \_/ __ \ 
/    |    \/    /|  |  /|  | \/\  ___/ 
\____|__  /_____ \____/ |__|    \___  >
        \/      \/                  \/ 
A P P   S E R V I C E   O N   L I N U X

Documentation: http://aka.ms/webapp-linux

**NOTE**: No files or system changes outside of /home will persist beyond your application's current session. /home is your application's persistent storage and is shared across all the server instances.


EOL
cat /etc/motd

echo "Setup openrc ..." && openrc && touch /run/openrc/softlevel

echo Updating /etc/ssh/sshd_config to use PORT $SSH_PORT
sed -i "s/SSH_PORT/$SSH_PORT/g" /etc/ssh/sshd_config

echo Starting ssh service...
rc-service sshd start

if [ ! -d /home/site/wwwroot/webapps ]
then
    mkdir -p /home/site/wwwroot
    cp -r /tmp/wildfly/webapps /home/site/wwwroot
fi

# COMPUTERNAME will be defined uniquely for each worker instance while running in Azure.
# If COMPUTERNAME isn't available, we assume that the container is running in a dev environment.
# If running in dev environment, define required environment variables.
if [ -z "$COMPUTERNAME" ]
then
    export COMPUTERNAME=dev
fi

# BEGIN: Define JAVA OPTIONS

# Configure JAVA OPTIONS. Make sure, we append the default values instead of prepending them.
# That way, the default values take precedence and we avoid the risk of an appsetting overriding the critical (default) properties.

export JAVA_OPTS="$JAVA_OPTS -Dwildfly.version=$WILDFLY_VERSION"
export JAVA_OPTS="$JAVA_OPTS -Djboss.http.port=$PORT"
export JAVA_OPTS="$JAVA_OPTS -Djboss.server.log.dir=/home/LogFiles"
export JAVA_OPTS="$JAVA_OPTS -noverify"

export JAVA_TOOL_OPTIONS="$JAVA_TOOL_OPTIONS -Djava.net.preferIPv4Stack=true"

# END: Define JAVA OPTIONS

# BEGIN: Configure /etc/profile

eval $(printenv | sed -n "s/^\([^=]\+\)=\(.*\)$/export \1=\2/p" | sed 's/"/\\\"/g' | sed '/=/s//="/' | sed 's/$/"/' >> /etc/profile)

# We want all ssh sesions to start in the /home directory
echo "cd /home" >> /etc/profile

# END: Configure /etc/profile

# BEGIN: Start management server in the background and wait for it to be ready

# Start Wildfly management server in the background. This helps us to proceed with the next steps like waiting for the server to be ready to run the startup script, etc
# Also, use the standalone-full.xml config (Java EE full-profile)
echo ***Starting Wildfly in the background...
$JBOSS_HOME/bin/standalone.sh --server-config=standalone-full.xml -b 0.0.0.0 --admin-only &

function wait_for_server() {
  until `$JBOSS_HOME/bin/jboss-cli.sh -c ":read-attribute(name=server-state)" 2> /dev/null | grep -q running`; do
    sleep 1
    echo ***Server not ready, sleeping again
  done
}

echo ***Waiting for admin server to be ready
wait_for_server
echo ***Admin server is ready

# END: Start management server in the background and wait for it to be ready

# BEGIN: Deploy the apps

# Copy wardeployed apps to local location and create marker file for each
if [ -f /home/site/wwwroot/app.ear ]
then
    echo "Found app.ear in /home/site/wwwroot, deploying it"
    ln -s /home/site/wwwroot/app.ear /tmp/wildfly/appservice/ROOT.ear
    $JBOSS_HOME/bin/jboss-cli.sh -c "deploy /tmp/wildfly/appservice/ROOT.ear"
elif [ -f /home/site/wwwroot/app.war ]
then
    echo "Found app.war in /home/site/wwwroot, deploying it"
    ln -s /home/site/wwwroot/app.war /tmp/wildfly/appservice/ROOT.war
    $JBOSS_HOME/bin/jboss-cli.sh -c "deploy /tmp/wildfly/appservice/ROOT.war"
else
    echo "Found neither app.ear nor app.war in /home/site/wwwroot, deploying apps in /home/site/wwwroot/webapps if any"

    for dirpath in /home/site/wwwroot/webapps/*
    do
        dir="$(basename -- $dirpath)"

        echo ***Copying $dirpath to $JBOSS_HOME/standalone/deployments/$dir.war
        cp -r $dirpath $JBOSS_HOME/standalone/deployments/$dir.war

        markerfile=$JBOSS_HOME/standalone/deployments/$dir.war.dodeploy

        echo ***Creating marker file $markerfile
        echo $dir > $markerfile
    done
fi

# END: Deploy the apps

# BEGIN: Process startup file / startup command, if any

# NOTE: Startup file / command, if any, is run only after installing the necessary modules and deploying all the apps.
#       This guarantees that in case the custom startup command / script issues a CLI "reload" command (which is not really needed),
#       apps would have been deployed and modules would have been configured by then already.

# Get the startup file path
if [ -n "$1" ]
then
    # Path defined in the portal will be available as an argument to this script
    STARTUP_FILE=$1
else
    # Default startup file path
    STARTUP_FILE=/home/startup.sh
fi

DEFAULT_STARTUP_FILE=/home/startup.sh
STARTUP_FILE=
STARTUP_COMMAND=

# The web app can be configured to run a custom startup command or a custom startup script
# This custom command / script will be available to us as a param ($1, $2, ...)
#
# IF $1 is a non-empty string AND an existing file, we treat $1 as a startup file (and ignore $2, $3, ...)
# IF $1 is a non-empty string BUT NOT an existing file, we treat $@ (equivalent of $1, $2, ... combined) as a startup command
# IF $1 is an empty string AND $DEFAULT_STARTUP_FILE exists, we use it as the startup file
# ELSE, we skip running the startup script / command
#
if [ -n "$1" ] # $1 is a non-empty string
then
    if [ -f "$1" ] # $1 file exists
    then
        STARTUP_FILE=$1
    else
        STARTUP_COMMAND=$@
    fi
elif [ -f $DEFAULT_STARTUP_FILE ] # Default startup file path exists
then
    STARTUP_FILE=$DEFAULT_STARTUP_FILE
fi

echo STARTUP_FILE=$STARTUP_FILE
echo STARTUP_COMMAND=$STARTUP_COMMAND

# If $STARTUP_FILE is a non-empty string, we need to run the startup file
# We first fix the EOL characters in it and then run it
if [ -n "$STARTUP_FILE" ]
then

    # Copy startup file to a temporary location and fix the EOL characters in the temp file (to avoid changing the original copy)
    TMP_STARTUP_FILE=/tmp/startup.sh
    echo Copying $STARTUP_FILE to $TMP_STARTUP_FILE and fixing EOL characters in $TMP_STARTUP_FILE
    cp $STARTUP_FILE $TMP_STARTUP_FILE
    dos2unix $TMP_STARTUP_FILE
    
    echo Running STARTUP_FILE: $TMP_STARTUP_FILE
    source $TMP_STARTUP_FILE
    echo Finished running startup file $TMP_STARTUP_FILE
else
    echo No STARTUP_FILE available.
fi

if [ -n "$STARTUP_COMMAND" ]
then
    echo Running STARTUP_COMMAND: "$STARTUP_COMMAND"
    $STARTUP_COMMAND
else
    echo No STARTUP_COMMAND defined.
fi

# END: Process startup file / startup command, if any

# BEGIN: Issue command to start application server

echo ***Starting JBOSS application server
$JBOSS_HOME/bin/jboss-cli.sh -c "reload"

# END: Issue command to start application server

# BEGIN: Bring management server to foreground

# Now that we are done with all the steps, bring Wildfly to the foreground again before exiting. If we don't do this, the container will exit after the script exits which we don't want
echo ***Container initialization complete, now bring Wildfly to foreground...
fg

# END: Bring management server to foreground

echo "***Exiting init_container.sh (Ideally we should never reach this line)"
