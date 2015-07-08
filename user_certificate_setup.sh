#! /bin/bash

#
#    COPYRIGHT LICENSE: This information contains sample code provided in source code form. You may copy, modify, and distribute
#    these sample programs in any form without payment to IBM® for the purposes of developing, using, marketing or distributing
#    application programs conforming to the application programming interface for the operating platform for which the sample code is written.
#    Notwithstanding anything to the contrary, IBM PROVIDES THE SAMPLE SOURCE CODE ON AN "AS IS" BASIS AND IBM DISCLAIMS ALL WARRANTIES,
#    EXPRESS OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, ANY IMPLIED WARRANTIES OR CONDITIONS OF MERCHANTABILITY, SATISFACTORY QUALITY,
#    FITNESS FOR A PARTICULAR PURPOSE, TITLE, AND ANY WARRANTY OR CONDITION OF NON-INFRINGEMENT. IBM SHALL NOT BE LIABLE FOR ANY DIRECT,
#    INDIRECT, INCIDENTAL, SPECIAL OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR OPERATION OF THE SAMPLE SOURCE CODE.
#    IBM HAS NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS OR MODIFICATIONS TO THE SAMPLE SOURCE CODE.



# Create a Root CA Certificate directory structure
mkdir rootca 
mkdir rootca/certs rootca/crl rootca/newcerts
touch rootca/serial

export HEXOUT=0123456789ABCDEF
# Create a serial list of random numbers
for y in {1..2048}
do
	export output=""
	for i in {1..16};
	do
		export randomnum=$((RANDOM%16))
		export output=$output${HEXOUT:$randomnum:1};
	done
	echo "$output" >> rootca/serial
done

touch rootca/index.txt

export ROOT_CA_SUBJECT="Development Root CA"

# Create the RSA keypair
# The parameter, 2048, represents the key length
openssl genrsa -des3 -out rootca/root_ca_key.pem -passout pass:passRoot 2048

#Sign a certificate with the keypair
openssl req -new -x509 -nodes -sha1 -days 365 -key rootca/root_ca_key.pem -out rootca/root_ca.crt -config openssl.cnf -subj "/CN=$ROOT_CA_SUBJECT" -extensions root_authority -passin pass:passRoot

# Create a Signing CA Certificate directory structure
mkdir signingca 
mkdir signingca/certs signingca/crl signingca/newcerts
touch signingca/serial

export HEXOUT=0123456789ABCDEF
# Create a serial list of random numbers
for y in {1..2048}
do
	export output=""
	for i in {1..16};
	do
		export randomnum=$((RANDOM%16))
		export output=$output${HEXOUT:$randomnum:1};
	done
	echo "$output" >> signingca/serial
done

touch signingca/index.txt

export SIGNING_CA_SUBJECT="Development Signing CA"

openssl genrsa -des3 -out signingca/signing_ca_key.pem -passout pass:passSigning 2048

openssl req -new -key signingca/signing_ca_key.pem -out signingca/signing_ca.csr -config openssl.cnf -subj "/CN=$SIGNING_CA_SUBJECT" -passin pass:passSigning

openssl ca -in signingca/signing_ca.csr -out signingca/signing_ca.crt -keyfile rootca/root_ca_key.pem -cert rootca/root_ca.crt -config openssl.cnf -name root_authority_ca_config -extensions signing_authority -md sha512 -days 365 -passin pass:passRoot

# Please use the full hostname of your server.  This is required, or SSL will break.
export SERVER_FULL_HOSTNAME=dev.yourcompany.com
mkdir server

# Create the RSA Key Pair and generate a CSR
openssl genrsa -des3 -out server/server_key.pem -passout pass:passServer 2048
openssl req -new -key server/server_key.pem -out server/server.csr -config openssl.cnf -subj "/CN=$SERVER_FULL_HOSTNAME" -passin pass:passServer

#Sign the CSR with the Signing CA
openssl ca -in server/server.csr -out server/server.crt -keyfile signingca/signing_ca_key.pem -cert signingca/signing_ca.crt -config openssl.cnf -name signing_authority_ca_config -extensions server_identity -md sha512 -days 365 -passin pass:passSigning

#Create a chain for the signing CA
cat signingca/signing_ca.crt rootca/root_ca.crt > signing_ca_chain.crt

#Create a chain for the server certificate
cat server/server.crt signingca/signing_ca.crt rootca/root_ca.crt > server_chain.crt

openssl pkcs12 -export -in signingca/signing_ca.crt -inkey ./signingca/signing_ca_key.pem -out signingca/signing_ca.p12 -passin pass:passSigning -passout pass:passSigningP12

openssl pkcs12 -export -in server_chain.crt -inkey server/server_key.pem -out server/server.p12 -passout pass:passServerP12 -passin pass:passServer
