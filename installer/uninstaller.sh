#!/bin/bash
#
# Copyright (c) 2019 Intel Corporation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

mark_release_to_be_deleted() {
    release_name=$1
    [[ $CHARTS_LIST =~ (^|[[:space:]])$release_name($|[[:space:]]) ]] && helm_arr+=("$release_name")
}

RELEASE_PREFIX="imm"

while getopts "qf:l:" opt; do
    case "$opt" in
    f)  export RELEASE_PREFIX=$OPTARG
        ;;
    q)  quiet="yes"
        ;;
    esac
done

shift $((OPTIND-1))


CHARTS_LIST="$RELEASE_PREFIX-mgt-api $RELEASE_PREFIX-crd $RELEASE_PREFIX-dex $RELEASE_PREFIX-ingress $RELEASE_PREFIX-openldap $RELEASE_PREFIX-minio"
HELM_LS_OUTPUT=`helm ls --output json`
HELM_LIST=`jq --arg namearg "Releases" '.[$namearg]' <<< $HELM_LS_OUTPUT`
K8S_NS_OUTPUT=`kubectl get ns --output=json`
K8S_NAMESPACES=`echo $K8S_NS_OUTPUT | jq '.items[].metadata.name'`
helm_arr=()
K8S_NS_ARR=()

[[ $K8S_NAMESPACES =~ "default-tenant" ]] && SINGLE_TENANT=1 || SINGLE_TENANT=0

cd ../scripts
if [[ "$quiet" != "yes" ]]; then
    echo "Uninstalling IMM. Following components will be removed:"
    echo "*Helm releases (mgt-api, crd etc.)"
    if [[ $SINGLE_TENANT == 1 ]]; then
        echo "*Default tenant with it's resources(models,endpoints etc.)"
    fi
    echo "Are you sure you want to uninstall IMM? Y/n"
    read DELETE_IMM
else
    DELETE_IMM="Y"
fi
if [[ $DELETE_IMM == "Y" ]]; then

    if [[ $SINGLE_TENANT == 1 ]]; then
        echo "Deleting default-tenant..."
        RESULT=`./imm -k rm t default-tenant`
    else
        RESULT=0
    fi

    if [[ "$RESULT" =~ "Tenant default-tenant deleted" || $RESULT == 0 ]]; then
        cd ../installer

        while read i; do
           echo $i
           RELEASE_NAME=`jq --arg namearg "Name" '.[$namearg]' <<< $i | tr -d '"'`
           mark_release_to_be_deleted $RELEASE_NAME
        done <<<"$(jq -c '.[]' <<< $HELM_LIST)"

        echo "Releases marked to be deleted:"

        for i in "${helm_arr[@]}"; do echo "$i" ; done

        if [[ "$quiet" == "yes" ]]; then
            for i in "${helm_arr[@]}"; do helm del --debug --purge $i ; done
        else
            read -p "Do you want to delete helm releases listed above Y/n?" DELETE_CHARTS
            [[ $DELETE_CHARTS != "n" ]] && for i in "${helm_arr[@]}"; do helm del --debug --purge $i ; done
        fi

        kubectl delete ing minio-ingress || true
        echo "IMM uninstalled successfully."
    elif [[ "$RESULT" =~ "Token not valid" ]]; then
        echo "Uninstallation aborted. Your token is invalid, please log in and try again."
    else
        echo "Uninstallation aborted. Unexpected error occurred during default-tenant removal."
    fi
else
    echo "Quiting uninstaller."
fi
