#! /usr/bin/env bash

__dir=$(cd $(dirname "${BASH_SOURCE[0]}") && pwd)

# prep local storage storageclass
manifest_path=${__dir}/postgres-operator/local-storage-provisioner.yaml
export provisioner_namespace=local-storage-provisioner
export provisioner_serviceaccount=local-storage-admin
export provisioner_ds_name=local-volume-provisioner
oc adm policy add-scc-to-user privileged \
  system:serviceaccount:${provisioner_namespace}:${provisioner_serviceaccount}
envsubst < ${manifest_path} | oc apply -f -
