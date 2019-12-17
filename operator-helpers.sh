#! /usr/bin/env bash

function subscribe_operator {
  local package_name=${1}
  local operator_namespace=${2:-openshift-operators}

  package=$(oc get packagemanifests ${package_name} -o json)
  if [[ -z ${package} ]]; then
    >&2 echo "${package_name} not available"
    exit 1
  fi
  default_channel=$(echo ${package} | jq '.status.defaultChannel')

  oc apply -f - <<EOF
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: ${package_name}-subscription
  namespace: ${operator_namespace}
spec:
  channel: ${default_channel}
  installPlanApproval: Automatic
  name: ${package_name}
  source: $(echo ${package} | jq '.status.catalogSource')
  sourceNamespace: $(echo ${package} | jq '.status.catalogSourceNamespace')
  startingCSV: $(echo ${package} | jq ".status.channels[] | select(.name == ${default_channel}) | .currentCSV")
EOF

}

function operator_group_for_ns {
  local target_namespace=${1}

  oc apply -f - <<EOF
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  name: local-operators
  namespace: ${target_namespace}
spec:
  targetNamespaces:
  - ${target_namespace}
EOF

}

# subscribe_operator mongodb-enterprise
