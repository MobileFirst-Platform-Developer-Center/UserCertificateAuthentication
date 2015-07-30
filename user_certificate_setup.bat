@ECHO off
@REM Copyright 2015 IBM Corp.
@REM
@REM Licensed under the Apache License, Version 2.0 (the "License");
@REM you may not use this file except in compliance with the License.
@REM You may obtain a copy of the License at
@REM
@REM http://www.apache.org/licenses/LICENSE-2.0
@REM
@REM Unless required by applicable law or agreed to in writing, software
@REM distributed under the License is distributed on an "AS IS" BASIS,
@REM WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
@REM See the License for the specific language governing permissions and
@REM limitations under the License.

SETLOCAL ENABLEDELAYEDEXPANSION

REM - [ACTION REQUIRED]
REM - Enter hostname before running
SET HOSTNAME=NUL

REM - Check for non-null hostname
IF %HOSTNAME% == NUL (
	ECHO Enter valid hostname in .bat file to continue.
	PAUSE
	EXIT
)

REM - Check for OpenSSL Libraries
openssl version > NUL || (
	PAUSE
	EXIT
)

REM - Check for OpenSSL configuration file (.cnf)
IF NOT EXIST openssl.cnf (
	ECHO No OpenSSL configuration file found.
	PAUSE
	EXIT
)

REM - Create directory structure for Development Root CA
MKDIR rootca
MKDIR rootca\certs
MKDIR rootca\crl
MKDIR rootca\newcerts
COPY NUL rootca\index.txt > NUL

REM - Create directory structure for Development Signing CA
MKDIR signingca
MKDIR signingca\certs
MKDIR signingca\crl
MKDIR signingca\newcerts
COPY NUL signingca\index.txt > NUL

REM - Create directory structure for Server Certificate
MKDIR server

REM - Generate serial numbers
openssl rand -hex -out rootca\serial 8
openssl rand -hex -out signingca\serial 8

REM - Create 2048 bit RSA keypair
ECHO [INFO] Generating keypair for Root CA
openssl genrsa -des3 -out rootca/root_ca_key.pem -passout pass:passRoot 2048

REM - Sign a certificate with the keypair
ECHO [INFO] Creating self-signed Root CA certificate
openssl req -new -x509 -nodes -sha1 -days 365 -key rootca/root_ca_key.pem -out rootca/root_ca.crt -config openssl.cnf -subj "/CN=Development Root CA" -extensions root_authority -passin pass:passRoot

REM - Create 2048 bit RSA keypair
ECHO [INFO] Generating keypair for Signing CA
openssl genrsa -des3 -out signingca/signing_ca_key.pem -passout pass:passSigning 2048

REM - Create CSR for Signing CA certificate
ECHO [INFO] Generating CSR for Signing CA certificate
openssl req -new -key signingca/signing_ca_key.pem -out signingca/signing_ca.csr -config openssl.cnf -subj "/CN=Development Signing CA" -passin pass:passSigning

REM - Create Signing CA certificate signed by Root CA
ECHO [INFO] Generating Signing CA certificate signed by Root CA
openssl ca -in signingca/signing_ca.csr -out signingca/signing_ca.crt -keyfile rootca/root_ca_key.pem -cert rootca/root_ca.crt -config openssl.cnf -name root_authority_ca_config -extensions signing_authority -md sha512 -days 365 -passin pass:passRoot

REM - Create 2048 bit RSA keypair
ECHO [INFO] Generating keypair for Server certificate
openssl genrsa -des3 -out server/server_key.pem -passout pass:passServer 2048

REM - Create CSR for Server certificate
ECHO [INFO] Generating CSR for Server certificate
openssl req -new -key server/server_key.pem -out server/server.csr -config openssl.cnf -subj "/CN=%HOSTNAME%" -passin pass:passServer

REM - Create Server certificate signed by Signing CA
ECHO [INFO] Generating Server certificate signed by Signing CA
openssl ca -in server/server.csr -out server/server.crt -keyfile signingca/signing_ca_key.pem -cert signingca/signing_ca.crt -config openssl.cnf -name signing_authority_ca_config -extensions server_identity -md sha512 -days 365 -passin pass:passSigning

REM - Create Signing CA server chain
ECHO [INFO] Creating Signing CA server chain
COPY rootca\root_ca.crt+signingca\signing_ca.crt signing_ca_chain.crt > NUL

REM - Create Server chain
ECHO [INFO] Creating Server chain
COPY rootca\root_ca.crt+signingca\signing_ca.crt+server\server.crt server_chain.crt > NUL

REM - Create Signing CA .p12
ECHO [INFO] Creating Signing CA .p12
openssl pkcs12 -export -in signingca/signing_ca.crt -inkey ./signingca/signing_ca_key.pem -out signingca/signing_ca.p12 -passin pass:passSigning -passout pass:passSigningP12

REM - Create Server .p12
ECHO [INFO] Creting Server .p12
openssl pkcs12 -export -in server_chain.crt -inkey server/server_key.pem -out server/server.p12 -passout pass:passServerP12 -passin pass:passServer

REM - Finish
PAUSE