#!/bin/bash

. ./resources/properties.sh

editCassandraYaml(){
	echo "### Generate cassandra.yaml for node $1"
	IP=$1
	TOKEN=$2

	cp $CURRENT_PATH/resources/cassandra.yaml.template $GENERATED_FILES/cassandra.yaml.$IP 
	sed  -i "s/{SNITCH}/$SNITCH/g" $GENERATED_FILES/cassandra.yaml.$IP
	sed  -i "s,{DATA_DIRECTORY},$DATA_DIRECTORY,g" $GENERATED_FILES/cassandra.yaml.$IP
	sed  -i "s,{TOKEN},$TOKEN,g" $GENERATED_FILES/cassandra.yaml.$IP
	sed  -i "s,{NODE_IP},$IP,g" $GENERATED_FILES/cassandra.yaml.$IP
	sed  -i "s,{PARTITIONER},$PARTITIONER,g" $GENERATED_FILES/cassandra.yaml.$IP
	sed  -i "s/{SEEDS}/$SEEDS/g" $GENERATED_FILES/cassandra.yaml.$IP
	sed  -i "s/{CLUSTER_NAME}/$CLUSTER_NAME/g" $GENERATED_FILES/cassandra.yaml.$IP
}

generateTokensRepartition(){
	echo "### Generate tokens repartitions for the cluster"
	TOKEN_GENERATOR_ARGUMENT=""
	for (( c=1; c<=${NUMBER_OF_DC}; c++ ))
	do
		TOKEN_GENERATOR_ARGUMENT="$TOKEN_GENERATOR_ARGUMENT `cat $CURRENT_PATH/resources/properties.sh | grep "NODE.*_DC=DC$c" | wc -l`"
	done
	$CURRENT_PATH/resources/token-generator $TOKEN_GENERATOR_ARGUMENT > $GENERATED_FILES/tokens
	sed -i '/DC.*:/d' $GENERATED_FILES/tokens
	sed -i 's/\s\+Node.*:\s\+//g' $GENERATED_FILES/tokens
}

generateCassandraTopologyFile(){
	echo "### Generate cassandra-topology.properties for the cluster"
	for (( c=1; c<=${NUMBER_OF_NODES}; c++ ))
		do
			NODE_HOST="NODE${c}_HOST"
			NODE_DC="NODE${c}_DC"
			NODE_RAC="NODE${c}_RAC"
			echo ${!NODE_HOST}=${!NODE_DC}:${!NODE_RAC} >> $GENERATED_FILES/cassandra-topology.properties
		done
}

deletePreviousGeneratedFiles(){
	if [ -d $GENERATED_FILES ]; then
		 echo "### Delete previous generated files"
		 find $GENERATED_FILES -mindepth 1 -delete
	else
		echo "### Create generatedFiles directory"
	 	mkdir $GENERATED_FILES
	fi
}

print(){
	echo "###"
	echo "### $1"
	echo "###"
}