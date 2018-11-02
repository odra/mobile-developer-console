#!/usr/bin/env bash

cd "$(dirname "$0")"
BASEDIR="$(pwd)"

minishift delete -f

MINISHIFT_ENABLE_EXPERIMENTAL=y minishift start --openshift-version v3.11.0 \
--extra-clusterup-flags "--enable=*,service-catalog,automation-service-broker,template-service-broker"

oc login -u system:admin

oc project default

rm -rf /tmp/mini-certs
mkdir /tmp/mini-certs
cd /tmp/mini-certs

oc get secret router-certs --template='{{index .data "tls.crt"}}' -n default  |  \
base64 --decode | sed -e '1,/^-----END RSA PRIVATE KEY-----$/ d'  >localcluster.crt

minishift ssh -- cat /var/lib/minishift/base/openshift-controller-manager/ca.crt >ca.crt
minishift ssh -- cat /var/lib/minishift/base/openshift-controller-manager/ca.key >ca.key
minishift ssh -- cat /var/lib/minishift/base/openshift-controller-manager/ca.serial.txt >ca.serial.txt

export ROUTING_SUFFIX=$(minishift ip).nip.io

oc adm ca create-server-cert \
    --signer-cert=ca.crt \
    --signer-key=ca.key \
    --signer-serial=ca.serial.txt \
    --hostnames='*.router.default.svc.cluster.local,router.default.svc.cluster.local,*.'$ROUTING_SUFFIX,$ROUTING_SUFFIX \
    --cert=router.crt \
    --key=router.key

cat router.crt ca.crt router.key >router.pem

oc get -o yaml --export secret router-certs > old-router-certs-secret.yaml

oc create secret tls router-certs --cert=router.pem \
    --key=router.key -o json --dry-run | \
    oc replace -f -

oc annotate service router \
    service.alpha.openshift.io/serving-cert-secret-name- \
    service.alpha.openshift.io/serving-cert-signed-by-

oc annotate service router \
    service.alpha.openshift.io/serving-cert-secret-name=router-certs

oc rollout latest dc/router

export ASB_PROJECT_NAME='openshift-automation-service-broker'

cd "$BASEDIR"

./post_install.sh

echo
echo "*******************"
echo "Cluster certificate is located in /tmp/mini-certs/localcluster.crt. Install it to your mobile device."