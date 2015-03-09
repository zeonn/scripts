#Setting variables:
#Oracle Middleware home dirrectory
MW_HOME=/u01/Oracle/Middleware/Oracle_Home
#Weblogic domain home dirrectory
DOMAIN_HOME=${MW_HOME}/user_projects/domains/base_domain
#CM home
CM_HOME=/u01/cm
#Host name
HOST_NAME=dpm-cm
#Managed server name
SERVER_NAME=cm

#Start AdminServer'а weblogic
${DOMAIN_HOME}/startWebLogic.sh > ${CM_HOME}/log/startWebLogic.log &
sleep 2m
#Start NodeManager
${DOMAIN_HOME}/bin/startNodeManager.sh > ${CM_HOME}/log/startNodeManager.log &
sleep 1m
#Start managed server
${DOMAIN_HOME}/bin/startManagedWebLogic.sh ${SERVER_NAME} http://${HOST_NAME}:7001 > ${CM_HOME}/log/startServerCM.log &
