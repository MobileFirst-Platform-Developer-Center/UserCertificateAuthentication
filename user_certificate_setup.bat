@ECHO off
@REM COPYRIGHT LICENSE: This information contains sample code provided in source code form. You may copy, modify, and distribute
@REM these sample programs in any form without payment to IBM® for the purposes of developing, using, marketing or distributing
@REM application programs conforming to the application programming interface for the operating platform for which the sample code is written.
@REM Notwithstanding anything to the contrary, IBM PROVIDES THE SAMPLE SOURCE CODE ON AN "AS IS" BASIS AND IBM DISCLAIMS ALL WARRANTIES,
@REM EXPRESS OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, ANY IMPLIED WARRANTIES OR CONDITIONS OF MERCHANTABILITY, SATISFACTORY QUALITY,
@REM FITNESS FOR A PARTICULAR PURPOSE, TITLE, AND ANY WARRANTY OR CONDITION OF NON-INFRINGEMENT. IBM SHALL NOT BE LIABLE FOR ANY DIRECT,
@REM INDIRECT, INCIDENTAL, SPECIAL OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR OPERATION OF THE SAMPLE SOURCE CODE.
@REM IBM HAS NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS OR MODIFICATIONS TO THE SAMPLE SOURCE CODE.

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