### BEGIN INIT INFO
# Provides:          primavera
# Required-Start:    $local_fs $remote_fs $network $syslog
# Required-Stop:     $local_fs $remote_fs $network $syslog
# Default-Start:     2 3 4
# Default-Stop:      0 1 6
# Short-Description: starts the Primavera P6EPPM Application server
# Description:       starts Primavera P6EPPM Application server using start-stop-daemon
# X-Start-Before:	 $all
### END INIT INFO

#Setting variables:
#Oracle Middleware home dirrectory
MW_HOME=/home/primavera/weblogic
#Weblogic P6EPPM domain home dirrectory
DOMAIN_HOME=${MW_HOME}/user_projects/domains/PrimaveraP6EPPM
#P6EPPM home
P6EPPM_HOME=/home/primavera/P6EPPM

#запуск AdminServer'а weblogic
${DOMAIN_HOME}/startWebLogic.sh &

#запуск NodeManager
${MW_HOME}/wlserver_10.3/server/bin/setWLSEnv.sh
${MW_HOME}/wlserver_10.3/server/bin/startNodeManager.sh &

#запуск стартового скрипта примаверы
${P6EPPM_HOME}/scripts/start_Primavera.sh