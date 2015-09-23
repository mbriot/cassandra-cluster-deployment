#!/bin/bash

CURRENT_PATH=`pwd`
PASSWORD=docubase
GENERATED_FILES=$CURRENT_PATH/generatedFiles

#get properties and functions
. $CURRENT_PATH/resources/properties.sh
. $CURRENT_PATH/resources/functions.sh

case "$1" in
	'deploy')
		print "Starting a new cluster deployment"
		deletePreviousGeneratedFiles
		generateTokensRepartition
		generateCassandraTopologyFile
		for (( c=1; c<=${NUMBER_OF_NODES}; c++ ))
		do
			TOKEN=`sed "${c}!d" $GENERATED_FILES/tokens`
			NODE_HOST="NODE${c}_HOST"
			editCassandraYaml ${!NODE_HOST} $TOKEN
			echo "### build and send cassandra directory to host ${!NODE_HOST}"
			cp -R $CASSANDRA_ARCHIVE_DIR $GENERATED_FILES/cassandra-${!NODE_HOST}
			cp $GENERATED_FILES/cassandra.yaml.${!NODE_HOST} $GENERATED_FILES/cassandra-${!NODE_HOST}/conf/cassandra.yaml
			cp $GENERATED_FILES/cassandra-topology.properties $GENERATED_FILES/cassandra-${!NODE_HOST}/conf/cassandra-topology.properties
			sshpass -p $PASSWORD scp -r $GENERATED_FILES/cassandra-${!NODE_HOST} ${DEFAULT_USER}@${!NODE_HOST}:${INSTALL_DIRECTORY}/cassandraAutoDeploy
		done
		;;
	'start')
		print "Starting nodes"
		for (( c=1; c<=${NUMBER_OF_NODES}; c++ ))
		do
			NODE_HOST="NODE${c}_HOST"
			echo "### starting node ${!NODE_HOST}"
			sshpass -p $PASSWORD ssh  ${DEFAULT_USER}@${!NODE_HOST} "${INSTALL_DIRECTORY}/cassandraAutoDeploy/bin/cassandra -p ${INSTALL_DIRECTORY}/cassandraAutoDeploy/cassandra.pid" >> $GENERATED_FILES/starting-nodes.log
		done
		;;
	'stop')
		print "Stopping nodes"
		for (( c=1; c<=${NUMBER_OF_NODES}; c++ ))
		do
			NODE_HOST="NODE${c}_HOST"
			echo "### stopping node ${!NODE_HOST}"
			sshpass -p $PASSWORD ssh  ${DEFAULT_USER}@${!NODE_HOST} "cat ${INSTALL_DIRECTORY}/cassandraAutoDeploy/cassandra.pid | xargs kill"
		done
		;;
	'delete-data')
		print "Delete cluster data"
		for (( c=1; c<=${NUMBER_OF_NODES}; c++ ))
		do
			NODE_HOST="NODE${c}_HOST"
			echo "### deleting data for node ${!NODE_HOST}"
			sshpass -p $PASSWORD ssh  ${DEFAULT_USER}@${!NODE_HOST} "rm -R ${DATA_DIRECTORY}/*"
		done
		;;
	'status')
		print "cluster status : "
		for (( c=1; c<=${NUMBER_OF_NODES}; c++ ))
		do
			NODE_HOST="NODE${c}_HOST"
			sshpass -p $PASSWORD ssh  ${DEFAULT_USER}@${!NODE_HOST} "${INSTALL_DIRECTORY}/cassandraAutoDeploy/bin/nodetool status"
			break
		done
		;;
	*)
		print "Unrecognized command : $1 "
		echo "Available commands :"
		echo -e '  deploy \t\t configure a new cluster based on properties.sh file and send proper cassandra directory to each nodes'
		echo -e '  start [nodes...] \t start the entire cluster or a set of nodes'
		echo -e '  stop [nodes...] \t stop the entire cluster or a set of nodes'
		echo -e '  delete-data \t\t delete all the data on the cluster'
		echo -e '  status \t\t play a nodetool status on one node'
		;;
esac
