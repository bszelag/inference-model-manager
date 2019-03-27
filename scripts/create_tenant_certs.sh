#!/bin/bash
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


generate_client_certs() {
 . ./generate_certs.sh
}

TENANT_NAME=$1
TENANT_CERT_DIR=./certs/$TENANT_NAME
mkdir -p $TENANT_CERT_DIR
cp ca.conf $TENANT_CERT_DIR
cp generate_certs.sh $TENANT_CERT_DIR
cd $TENANT_CERT_DIR
generate_client_certs
echo "Client certificates for inference are stored in `pwd`"
rm generate_certs.sh
cd -
