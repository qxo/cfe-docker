#!/bin/bash
#
# Takes an arbitrary set of parameters as commands that should be running.
# Writes them as "basename(cmd), cmd" to /var/cfengine/inputs/processes_run.csv
# and starts CFEngine.
# If you are passing arguments to a command, quote the command with the arguments,
# e.g. docker run myimage "/etc/init.d/apache2 start" "/usr/bin/mongod --noprealloc --smallfiles"
# The commands' basename should become a process in order to be detected by CFEngine.
# The commands will be run as root in a shell.

#clean history
sed -i  -n '/^[^#]*$/{N;d};p' /var/cfengine/inputs/processes_run.csv
# if the command "cmd" not a daemon (just a script startup other deamon process)
# we should identitify by the daemon process like:
# 1. append process name with '#' eg: /startOracle.sh#tnslsnr
# 2. on script add daemon process identitify line ,eg '#cfengine-monitor-proccess:tnslsnr'
for cmd in "$@"
do
  pn=$(echo "$cmd" | awk -F'#' '{print $2;}');
  if [ -z "$pn" ] ; then
    file=${cmd%% *}
    pn=${file##*/}
    if [ -f $file ] ; then
      mp=$(grep '^#cfengine-monitor-process:.*$' $file | awk -F':' '{print $2}');
      if [ -n "$mp" ] ; then
        pn="$mp"
      fi
    fi
  else
    cmd=$(echo "$cmd" | awk -F'#' '{print $1;}');
  fi
  echo "$pn, $cmd" >> /var/cfengine/inputs/processes_run.csv
done

/var/cfengine/bin/cf-agent
/var/cfengine/bin/cf-execd -F
