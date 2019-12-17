#! /usr/bin/env bash

__dir=$(cd $(dirname "${BASH_SOURCE[0]}") && pwd)
source ${__dir}/operator-helpers.sh

# subscribe operator to default namespace
subscribe_operator crunchy-postgres-operator

# TODO: automate the following:
# modify CSV to apply NAMESPACE var to each container
# or create operator in target namespace
# oc get csv -n openshift-operators postgresoperator -o json
# replace `NAMESPACE` env var with watched namespaces
# all namespaces *must* exist
# export NAMESPACE=pgouser1,pgouser2

# apply cluster
export pgcluster_namespace=pgouser1
export pgcluster_name=fromcrd
export pgcluster_storageclass=local-disks
export pgcluster_fsgroup=26
# have not found a way to modify this
export pgcluster_serviceaccount=default
redhat_registry_secret_name=redhat-registry

ns=$(oc get namespace ${pgcluster_namespace} 2> /dev/null)
if [[ -z "${ns}" ]]; then
  oc create namespace ${pgcluster_namespace}
fi

# generate SSH key pair for configuring "pgo-backrest"
stat ${__dir}/${pgcluster_name}-key &> /dev/null
if [[ $? != 0 ]]; then
	ssh-keygen -N '' -f ${__dir}/${pgcluster_name}-key
fi

# base64 encode and save in temp vars
export public_key=$(cat ${__dir}/${pgcluster_name}-key.pub | base64 -w 0)
export private_key=$(cat ${__dir}/${pgcluster_name}-key | base64 -w 0)

# interpolate generated keys and apply
envsubst < ${__dir}/postgres-operator/backrest-secret.yaml | oc apply -f -

# pg containers must run with `anyuid` scc
oc adm policy add-scc-to-user anyuid \
	system:serviceaccount:${pgcluster_namespace}:${pgcluster_serviceaccount}
# set pull secret for registry.connect.redhat.com
secret=$(oc get secret ${redhat_registry_secret_name} 2> /dev/null)
if [[ -z "${secret}" ]]; then
	oc create secret generic ${redhat_registry_secret_name} \
		--type=kubernetes.io/dockerconfigjson \
		--from-file=.dockerconfigjson=${__dir}/redhat.dockerconfig.json
fi
oc secrets link -n ${pgcluster_namespace} \
	${pgcluster_serviceaccount} ${redhat_registry_secret_name} \
	--for=pull
envsubst < ${__dir}/postgres-operator/user-secrets.yaml | oc apply -f -
envsubst < ${__dir}/postgres-operator/cluster.yaml | oc apply -f -
