#!/bin/bash

${TraceF-}

# commands
# self-sign
# create
# trust
# request

###############
## defaults
: ${SSLDIR:=ssl}
: ${SSLCADIR:=$SSLDIR/certificate-authority}
: ${SSLFILE:=server}
: ${SSLCAFILE:=ca}

opt_ca_bits_default=4096 ## bits for the CA certificate - should be more than "normal"
opt_bits_default=2048    ## default # bits for server certificates
opt_intermediate_dir_default=intermediate
opt_days_default=365
opt_years_default=1      ## default expiry for server certificates
opt_private_key_cipher_default_if=aes256
opt_country_default=
opt_province_default=
opt_city_default=
opt_company_default=
opt_fqdn_default=
[ "$opt_company_default" ] && opt_department_default="$opt_company_default Certificate Authority"
[ "$opt_company_default" ] && opt_root_common_name_default="$opt_company_default Root CA"
[ "$opt_company_default" ] && opt_intermediate_common_name_default="$opt_company_default Intermediate CA"

###############
(( twenty_years_of_days = 20 * 365 + 10 ))

###############
## functions
prompt_opt() {
  local variable default prompt response required

  while [ $# -gt 0 ]
  do
    case "$1" in
    -r|-required) required=yes; shift ;;
    -d|-default) default=$2; shift; shift ;;
    --) shift; break ;;
    -*) echo "bad option for prompt_opt: $1" >&2; exit 1 ;;
    *) break ;;
    esac
  done

  variable="$1"; shift
  prompt="$*"

  while true
  do
    [ -n "$default" ] && echo -n "$prompt (default: $default): " || echo -n "${prompt}: "
    read response
    [ -z "$response" ] && response="$default"
    [ -z "$required" -o -n "$response" ] && break
  done

  eval "${variable}='$response'"
}

set_ca_default() {
  local key var
  key="$1"
  var="$2"
  eval "$var='$(grep "$key" openssl.cnf | sed -e 's/^.* = //')'"
}

usage() {
  local exitcode message

  while [ $# -gt 0 ]
  do
    case "$1" in
    -exit|-exitcode) exitcode=$2; shift; shift ;;
    --) shift; break ;;
    -*) shift ;;
    *) break ;;
    esac
  done

  message="$*"
  [ -n "$message" ] && echo "$message"

case "$COMMAND" in
self-sign)
  cat <<EOF
Generate a self-signed certificate for a web server.

simple-ca self-sign [Options] fully.qualified.server.domain.name

Options
  -bits NUMBER : number of bits in the key (default ${opt_bits_default:-none})
  -days NUMBER : number of days to certificate expiry (default ${opt_days_default:-none})
  -aes128 -aes192 -aes256 -camellia128 -camellia192 -camellia256
      -des -des3 -idea : type of encryption to use for the private keys.
      default is no encryption, no password.
  -nopassword : no password on the private keys.  this is the default.
  -withpassword : encrypt the private keys, with ${opt_private_key_cipher_default_if:-none} cipher.
      aliases : -password, -encrypt-private-key
  -country COUNTRY : two letter ISO code for certificate authority country.
      default is ${opt_country_default:-none}.
  -province PROVINCE : province name for certificate authority.
      default is ${opt_province_default:-none}.
      alias : -state
  -city CITY : city for certificate authority.
      default is ${opt_city_default:-none}.
  -company COMPANY : name of certificate authority.
      default is ${opt_company_default:-none}.
      alias : -organization
  -department DEPARTMENT : department handling certs.
      default is ${opt_department_default:-none}.
      aliases are -section, -unit
  -email EMAIL : contact email
EOF
  ;;

request)
  cat <<EOF
Generate a request for a signed certificate for a web server.

simple-ca request [Options] fully.qualified.server.domain.name

Options
  -bits NUMBER : number of bits in the key (default ${opt_bits_default:-none})
  -days NUMBER : number of days to certificate expiry (default ${opt_days_default:-none})
  -aes128 -aes192 -aes256 -camellia128 -camellia192 -camellia256
      -des -des3 -idea : type of encryption to use for the private keys.
      default is no encryption, no password.
  -nopassword : no password on the private keys.  this is the default.
  -withpassword : encrypt the private keys, with ${opt_private_key_cipher_default_if:-none} cipher.
      aliases : -password, -encrypt-private-key
  -country COUNTRY : two letter ISO code for certificate authority country.
      default is ${opt_country_default:-none}.
  -province PROVINCE : province name for certificate authority.
      default is ${opt_province_default:-none}.
      alias : -state
  -city CITY : city for certificate authority.
      default is ${opt_city_default:-none}.
  -company COMPANY : name of certificate authority.
      default is ${opt_company_default:-none}.
      alias : -organization
  -department DEPARTMENT : department handling certs.
      default is ${opt_department_default:-none}.
      aliases are -section, -unit
  -email EMAIL : contact email
EOF
  ;;

trust)
  cat <<EOF
Generate trusted certificates for a web server, using the configured
Certificate Authority, or generating one on the fly, so that a trusted
server certificate chain can be created.

simple-ca trust [Options] fully.qualified.server.domain.name

If a root Certificate Authority is found in $SSLCADIR, and an
intermediate Certificate Authority is found, then those will be
used to generate the trusted certificate chain.  Otherwise, they
will be created.

Options
  -new : create CA as new.  if CA exists, scrub it.
  -new-intermediate : create Intermediate CA as new.  if it exists, scrub it.
  -intermediate INTERMEDIATE-DIRECTORY : Intermediate CA to use.
    Optional name of directory within the CA directory to hold
    the Intermediate CA data.  default is ${opt_intermediate_dir_default:-none}.
  -bits NUMBER : number of bits in the key (default ${opt_bits_default:-none})
  -years NUMBER : default number of years to certificate
      expiry (default ${opt_years_default:-none})
  -days NUMBER : number of days to certificate expiry (default ${opt_days_default:-none})
  -aes128 -aes192 -aes256 -camellia128 -camellia192 -camellia256
      -des -des3 -idea : type of encryption to use for the private keys.
      default is no encryption, no password.
  -nopassword : no password on the private keys.  this is the default.
  -withpassword : encrypt the private keys, with ${opt_private_key_cipher_default_if:-none} cipher.
      aliases : -password, -encrypt-private-key
  -country COUNTRY : two letter ISO code for certificate authority country.
      default is ${opt_country_default:-none}.
  -province PROVINCE : province name for certificate authority.
      default is ${opt_province_default:-none}.
      alias : -state
  -city CITY : city for certificate authority.
      default is ${opt_city_default:-none}.
  -company COMPANY : name of certificate authority.
      default is ${opt_company_default:-none}.
      alias : -organization
  -department DEPARTMENT : department handling certs.
      default is ${opt_department_default:-none}.
      aliases are -section, -unit
  -email EMAIL : contact email
EOF
  ;;

create)
  cat <<EOF
Create a Certificate Authority for generating free https certificates

simple-ca create [Options] [ IntermediateDirectory [ IntermediateCommonName ] ]

This creates the self-signed root certificate, and an intermediate
certificate.  The expiry on those certificates will be 20 years.
The private key for those certificates may or may not be encrypted
with a password.  The intermediate certificate is what is used
to sign server certificates.

There may be multiple intermediates for any given root certificate.

IntermediateDirectory
  Optional name of directory within the CA directory to hold
  the Intermediate CA data.  default is ${opt_intermediate_dir_default:-none}.

IntermediateCommonName
  Optional common name for the Intermediate Certificate Authority.
  default is ${{opt_intermediate_common_name_default:-none}.

Options
  -new : create CA as new.  if CA exists, scrub it.
  -new-intermediate : create Intermediate CA as new.  if it exists, scrub it.
  -bits NUMBER : number of bits in the key (default ${opt_bits_default:-none})
  -years NUMBER : default number of years to certificate
      expiry (default ${opt_years_default:-none})
  -aes128 -aes192 -aes256 -camellia128 -camellia192 -camellia256
      -des -des3 -idea : type of encryption to use for the private keys.
      default is no encryption, no password.
  -nopassword : no password on the private keys.  this is the default.
  -withpassword : encrypt the private keys, with ${opt_private_key_cipher_default_if:-none} cipher.
      aliases : -password, -encrypt-private-key
  -country COUNTRY : two letter ISO code for certificate authority country.
      default is $opt_country_default:-none}.
  -province PROVINCE : province name for certificate authority.
      default is $opt_province_default:-none}.
      alias : -state
  -city CITY : city for certificate authority.
      default is $opt_city_default:-none}.
  -company COMPANY : name of certificate authority.
      default is $opt_company_default:-none}.
      alias : -organization
  -department DEPARTMENT : department handling certs.
      default is $opt_department_default:-none}.
      aliases are -section, -unit
  -email EMAIL : contact email
EOF
  ;;
  
*)
  cat <<EOF
Generate SSL certificates.

simple-ca COMMAND [ Options ] [ Arguments ]

COMMAND may be

  self-sign - generate a self-signed certificate, with corresponding private key.
  create - create a certificate authority for signing server certs.
  trust - generate the trusted server certificate.
  request - generate a CSR certificate signing request.

EOF
  ;;
esac

  [ -n "$exitcode" ] && exit $exitcode
}

case "$1" in
self-sign) COMMAND=self-sign; shift ;;
create) COMMAND=create; shift ;;
trust) COMMAND=trust; shift ;;
request) COMMAND=request; shift ;;
*) usage -exit 1 "Invalid command $1" >&2 ;;
esac

while [ $# -gt 0 ]
do
  case "$1" in
  -new) opt_scrub_root_ca=yes; shift ;;
  -new-intermediate) opt_scrub_intermediate_ca=yes; shift ;;
  -intermediate) opt_intermediate_dir="$2"; shift; shift ;;
  -bits) opt_bits=$2; shift; shift ;;
  -days) opt_days=$2; shift; shift ;;
  -years) opt_years=$2; shift; shift ;;
  -aes128|-aes192|-aes256|-camellia128|-camellia192|-camellia256|-des|-des3|-idea) opt_private_key_cipher="$1"; shift ;;
  -nopassword) opt_private_key_cipher=""; shift ;;
  -withpassword|-password|-encrypt-private-key) opt_private_key_cipher="-$opt_private_key_cipher_default_if"; shift ;;
  -country) opt_country=$2; shift; shift ;;
  -province|-state) opt_province=$2; shift; shift ;;
  -city) opt_city=$2; shift; shift ;;
  -company|-organization) opt_company=$2; shift; shift ;;
  -department|-section|-unit) opt_department=$2; shift; shift ;;
  -email) opt_email=$2; shift; shift ;;
  --) shift; break ;;
  '-?') usage -exit 0 Help ;;
  -*) usage -exit 1 "Invalid option $1" >&2 ;;
  *) break ;;
  esac
done

promptnum=0

case "$COMMAND" in
self-sign|request)
  [ -d "$SSLDIR" ] || mkdir -p "$SSLDIR"

  opt_fqdn=$1; shift
  [ -z "$opt_fqdn" ] && prompt_opt -d "$opt_fqdn_default" opt_fqdn "Fully Qualified Domain Name for your Web Server"
  ;;

trust)
  if [ -f "$1" ]; then
    opt_certificate_signing_request_file=$(readlink -f "$1")
    opt_fqdn=$(openssl req -text -noout -verify -in "$opt_certificate_signing_request_file" 2> /dev/null | grep Subject: | sed -e 's/^.*CN=//' -e 's/\/.*$//')
  else
    opt_fqdn="$1"
  fi
  shift

  [ -z "$opt_fqdn" ] && prompt_opt -d "$opt_fqdn_default" opt_fqdn "Fully Qualified Domain Name for your Web Server"
  [ -z "$opt_intermediate_dir" ] && prompt_opt -d "$opt_intermediate_dir_default" opt_intermediate_dir "Intermediate CA directory name"
  ;;

create)
  opt_intermediate_dir=$1; shift
  [ -z "$opt_intermediate_dir" ] && prompt_opt -d "$opt_intermediate_dir_default" opt_intermediate_dir "Intermediate CA directory name"
  ;;
esac

case "$COMMAND" in
trust|create)
  newcaflag=
  [ -d "$SSLCADIR" ] || { mkdir -p "$SSLCADIR"; newcaflag=yes; }

  pushd "$SSLCADIR" > /dev/null
  for subdir in certs crl newcerts private
  do
    [ -d "$subdir" ] || { mkdir $subdir; newcaflag=yes; }
  done

  if [ "$newcaflag" ]; then
    echo "Creating certificate authority in $SSLCADIR"
  elif [ "$opt_scrub_root_ca" ]; then
    echo "Re-creating certificate authority in $SSLCADIR"
  else
    if [ -f openssl.cnf ]; then
      set_ca_default default_bits                    opt_bits_default
      set_ca_default countryName_default             opt_country_default
      set_ca_default stateOrProvinceName_default     opt_province_default
      set_ca_default localityName_default            opt_city_default
      set_ca_default 0.organizationName_default      opt_company_default
      set_ca_default organizationalUnitName_default  opt_department_default
      set_ca_default emailAddress_default            opt_email_default
    fi

    if [ -d "$opt_intermediate_dir" ]; then
      if [ "$opt_scrub_intermediate_ca" ]; then
        echo "Re-creating Intermediate Certificate Authority in $SSLCADIR"
      elif [ ".$COMMAND" = .create ]; then
        echo "Intermediate Certificate Authority already exists in $SSLCADIR"
        exit 1
      fi
    else
      echo "Creating new Intermediate Certificate Authority in $SSLCADIR"
    fi
  fi >&2
  popd > /dev/null
  ;;
esac

[ ".$opt_ca_bits" = "." ] && opt_ca_bits=$opt_ca_bits_default
[ ".$opt_bits" = "." ] && opt_bits=$opt_bits_default
[ ".$opt_years" = "." ] && opt_years=$opt_years_default
[ ".$opt_days" = "." ] && opt_days=$opt_days_default

[ ".$opt_country" = "." ] && opt_country=$opt_country_default
[ ".$opt_country" = "." ] && prompt_opt -r opt_country Country 2 letter ISO code
[ ".$opt_province" = "." ] && opt_province=$opt_province_default
[ ".$opt_province" = "." ] && prompt_opt opt_province Full Province or State name
[ ".$opt_city" = "." ] && opt_city=$opt_city_default
[ ".$opt_city" = "." ] && prompt_opt opt_city City name
[ ".$opt_company" = "." ] && prompt_opt -d "$opt_company_default" opt_company Organization or Company Name
[ ".$opt_department" = "." ] && opt_department="$opt_company Certificate Authority"
[ ".$opt_root_common_name" = "." ] && opt_root_common_name="$opt_company Root CA"
[ ".$opt_email" = "." ] && prompt_opt -r -d "$opt_email_default" opt_email Email Address

case "$COMMAND" in
self-sign)
  if [ ".$opt_private_key_cipher" = . ]; then
    (( promptnum = promptnum + 1 ))
    echo ""
    echo "$promptnum) Generate $opt_bits bit private key (unencrypted)"
    $ECHO openssl genrsa -out "${SSLDIR}/${SSLFILE}.key.pem" $opt_bits
  else
    (( promptnum = promptnum + 1 ))
    echo ""
    echo "$promptnum) Generate encrypted $opt_bits bit private key (encryption password will be prompted for)"
    $ECHO openssl genrsa $opt_private_key_cipher -out "${SSLDIR}/${SSLFILE}.key.pem" $opt_bits
  fi
  $ECHO chmod 700 "${SSLDIR}/${SSLFILE}.key.pem"

  (( promptnum = promptnum + 1 ))
  echo ""
  echo "$promptnum) generate the certificate signing request (csr) for $opt_days days using"
  echo "   Country Name (2 letter code)           : $opt_country"
  echo "   State or Province Name (full name)     : $opt_province"
  echo "   Locality Name (eg, city)               : $opt_city"
  echo "   Organization Name (eg, company)        : $opt_company"
  echo "   Organizational Unit Name (eg, section) : $opt_department"
  echo "   Web Server Fully Qualified Domain Name : $opt_fqdn"
  echo "   Email Address                          : $opt_email"

  [ ".$opt_private_key_cipher" != . ] && { echo ""; echo "private key password will be prompted for ..."; }
  $ECHO openssl req -new -key "${SSLDIR}/${SSLFILE}.key.pem" -out "${SSLDIR}/${SSLFILE}.csr.pem" -days $opt_days -subj "/C=$opt_country/ST=$opt_province/L=$opt_city/O=$opt_company/OU=$opt_department/CN=$opt_fqdn/emailAddress=$opt_email"

  (( promptnum = promptnum + 1 ))
  echo ""
  echo "$promptnum) generate self signed ssl certificate for $opt_days days"
  $ECHO openssl x509 -req -days $opt_days -in "${SSLDIR}/${SSLFILE}.csr.pem" -signkey "${SSLDIR}/${SSLFILE}.key.pem" -out "${SSLDIR}/${SSLFILE}.cert.pem"
  $ECHO chmod 444 "${SSLDIR}/${SSLFILE}.cert.pem"

  (( promptnum = promptnum + 1 ))
  echo ""
  echo "$promptnum) verify certificate"
  $ECHO openssl x509 -noout -text -in "${SSLDIR}/${SSLFILE}.cert.pem"

  echo ""
  [ -f "${SSLDIR}/${SSLFILE}.orig.key.pem" ] && { echo removing "${SSLDIR}/${SSLFILE}.orig.key.pem"; $ECHO rm "${SSLDIR}/${SSLFILE}.orig.key.pem"; }
  [ -f "${SSLDIR}/${SSLFILE}.csr.pem" ] && { echo removing "${SSLDIR}/${SSLFILE}.csr.pem"; $ECHO rm "${SSLDIR}/${SSLFILE}.csr.pem"; }

  echo ""
  echo "self-signed private key ${SSLDIR}/${SSLFILE}.key.pem"
  echo "self-signed certificate ${SSLDIR}/${SSLFILE}.cert.pem"

  exit 0
  ;;

request)
  if [ ".$opt_private_key_cipher" = . ]; then
    (( promptnum = promptnum + 1 ))
    echo ""
    echo "$promptnum) Generate $opt_bits bit private key (unencrypted)"
    $ECHO openssl genrsa -out "${SSLDIR}/${opt_fqdn}.key.pem" $opt_bits
  else
    (( promptnum = promptnum + 1 ))
    echo ""
    echo "$promptnum) Generate encrypted $opt_bits bit private key (encryption password will be prompted for)"
    $ECHO openssl genrsa $opt_private_key_cipher -out "${SSLDIR}/${opt_fqdn}.key.pem" $opt_bits
  fi
  $ECHO chmod 700 "${SSLDIR}/${opt_fqdn}.key.pem"

  (( promptnum = promptnum + 1 ))
  echo ""
  echo "$prompnum) generate the certificate signing request (csr) for $opt_days days using"
  echo "   Country Name (2 letter code)           : $opt_country"
  echo "   State or Province Name (full name)     : $opt_province"
  echo "   Locality Name (eg, city)               : $opt_city"
  echo "   Organization Name (eg, company)        : $opt_company"
  echo "   Organizational Unit Name (eg, section) : $opt_department"
  echo "   Web Server Fully Qualified Domain Name : $opt_fqdn"
  echo "   Email Address                          : $opt_email"

  [ ".$opt_private_key_cipher" != . ] && { echo ""; echo "$opt_fqdn private key password will be prompted for ..."; }
  $ECHO openssl req -key "${SSLDIR}/${opt_fqdn}.key.pem" -new -sha256 -out "${SSLDIR}/${opt_fqdn}.csr.pem" -days $opt_days -subj "/C=$opt_country/ST=$opt_province/L=$opt_city/O=$opt_company/OU=$opt_department/CN=$opt_fqdn/emailAddress=$opt_email"

  echo ""
  echo "private key ${SSLDIR}/${opt_fqdn}.key.pem"
  echo "certificate request ${SSLDIR}/${opt_fqdn}.csr.pem"

  exit 0
  ;;

trust|create)
  opt_intermediate_common_name_default="$opt_company Intermediate CA"

  [ ".$COMMAND" = .create ] && opt_intermediate_common_name="$*"
  [ -z "$opt_intermediate_common_name" ] && prompt_opt -d "$opt_intermediate_common_name_default" opt_intermediate_common_name "Intermediate name"

  (( default_server_cert_expiry = opt_years * 365 + 10 ))
  ;;
esac

if [ -n "$newcaflag" -o -n "$opt_scrub_root_ca" ]; then
  pushd "$SSLCADIR" > /dev/null

  chmod 700 private
  echo -n "" > index.txt
  echo 1000 > serial
  cat > openssl.cnf <<-EOF
    # OpenSSL root CA configuration file.
    # Copy to '$PWD/openssl.cnf'.

    [ ca ]
    # 'man ca'
    default_ca = CA_default

    [ CA_default ]
    # Directory and file locations.
    dir               = $PWD
    certs             = $PWD/certs
    crl_dir           = $PWD/crl
    new_certs_dir     = $PWD/newcerts
    database          = $PWD/index.txt
    serial            = $PWD/serial
    RANDFILE          = $PWD/private/.rand

    # The root key and root certificate.
    private_key       = $PWD/private/${SSLCAFILE}.key.pem
    certificate       = $PWD/certs/${SSLCAFILE}.cert.pem

    # For certificate revocation lists.
    crlnumber         = $PWD/crlnumber
    crl               = $PWD/crl/${SSLCAFILE}.crl.pem
    crl_extensions    = crl_ext
    default_crl_days  = 30

    # SHA-1 is deprecated, so use SHA-2 instead.
    default_md        = sha256

    name_opt          = ca_default
    cert_opt          = ca_default
    default_days      = $default_server_cert_expiry
    preserve          = no
    policy            = policy_strict

    [ policy_strict ]
    # The root CA should only sign intermediate certificates that match.
    # See the POLICY FORMAT section of 'man ca'.
    countryName             = match
    stateOrProvinceName     = match
    organizationName        = match
    organizationalUnitName  = optional
    commonName              = supplied
    emailAddress            = optional

    [ policy_loose ]
    # Allow the intermediate CA to sign a more diverse range of certificates.
    # See the POLICY FORMAT section of the 'ca' man page.
    countryName             = optional
    stateOrProvinceName     = optional
    localityName            = optional
    organizationName        = optional
    organizationalUnitName  = optional
    commonName              = supplied
    emailAddress            = optional

    [ req ]
    # Options for the 'req' tool ('man req').
    default_bits        = $opt_bits
    distinguished_name  = req_distinguished_name
    string_mask         = utf8only

    # SHA-1 is deprecated, so use SHA-2 instead.
    default_md          = sha256

    # Extension to add when the -x509 option is used.
    x509_extensions     = v3_ca

    [ req_distinguished_name ]
    # See <https://en.wikipedia.org/wiki/Certificate_signing_request>.
    countryName                     = Country Name (2 letter code)
    stateOrProvinceName             = State or Province Name
    localityName                    = Locality Name
    0.organizationName              = Organization Name
    organizationalUnitName          = Organizational Unit Name
    commonName                      = Common Name
    emailAddress                    = Email Address

    # Optionally, specify some defaults.
    countryName_default             = $opt_country
    stateOrProvinceName_default     = $opt_province
    localityName_default            = $opt_city
    0.organizationName_default      = $opt_company
    organizationalUnitName_default  = $opt_department
    emailAddress_default            = $opt_email

    [ v3_ca ]
    # Extensions for a typical CA ('man x509v3_config').
    subjectKeyIdentifier = hash
    authorityKeyIdentifier = keyid:always,issuer
    basicConstraints = critical, CA:true
    keyUsage = critical, digitalSignature, cRLSign, keyCertSign

    [ v3_intermediate_ca ]
    # Extensions for a typical intermediate CA ('man x509v3_config').
    subjectKeyIdentifier = hash
    authorityKeyIdentifier = keyid:always,issuer
    basicConstraints = critical, CA:true, pathlen:0
    keyUsage = critical, digitalSignature, cRLSign, keyCertSign

    [ usr_cert ]
    # Extensions for client certificates ('man x509v3_config').
    basicConstraints = CA:FALSE
    nsCertType = client, email
    nsComment = "OpenSSL Generated Client Certificate"
    subjectKeyIdentifier = hash
    authorityKeyIdentifier = keyid,issuer
    keyUsage = critical, nonRepudiation, digitalSignature, keyEncipherment
    extendedKeyUsage = clientAuth, emailProtection

    [ server_cert ]
    # Extensions for server certificates ('man x509v3_config').
    basicConstraints = CA:FALSE
    nsCertType = server
    nsComment = "OpenSSL Generated Server Certificate"
    subjectKeyIdentifier = hash
    authorityKeyIdentifier = keyid,issuer:always
    keyUsage = critical, digitalSignature, keyEncipherment
    extendedKeyUsage = serverAuth

    [ crl_ext ]
    # Extension for CRLs ('man x509v3_config').
    authorityKeyIdentifier=keyid:always

    [ ocsp ]
    # Extension for OCSP signing certificates ('man ocsp').
    basicConstraints = CA:FALSE
    subjectKeyIdentifier = hash
    authorityKeyIdentifier = keyid,issuer
    keyUsage = critical, digitalSignature
    extendedKeyUsage = critical, OCSPSigning
EOF

  if [ ".$opt_private_key_cipher" = . ]; then
    (( promptnum = promptnum + 1 ))
    echo ""
    echo "$promptnum) Generate $opt_ca_bits bit root certificate authority private key (unencrypted)"
    $ECHO openssl genrsa -out "private/${SSLCAFILE}.key.pem" $opt_ca_bits
  else
    (( promptnum = promptnum + 1 ))
    echo ""
    echo "$promptnum) Generate encrypted $opt_ca_bits bit root certificate authority private key (encryption password will be prompted for)"
    $ECHO openssl genrsa $opt_private_key_cipher -out "private/${SSLCAFILE}.key.pem" $opt_ca_bits
  fi
  $ECHO chmod 400 "private/${SSLCAFILE}.key.pem"

  (( promptnum = promptnum + 1 ))
  echo ""
  echo "$promptnum) generate the root certificate with expiry in 20 years ($twenty_years_of_days days) using"
  echo "   Country Name (2 letter code)           : $opt_country"
  echo "   State or Province Name (full name)     : $opt_province"
  echo "   Locality Name (eg, city)               : $opt_city"
  echo "   Organization Name (eg, company)        : $opt_company"
  echo "   Organizational Unit Name (eg, section) : $opt_department"
  echo "   CA Common Name                         : $opt_root_common_name"
  echo "   Email Address                          : $opt_email"

  [ ".$opt_private_key_cipher" != . ] && { echo ""; echo "the root certificate private key password will be prompted for ..."; }
  $ECHO openssl req -config openssl.cnf -key "private/${SSLCAFILE}.key.pem" -new -x509 -days $twenty_years_of_days -sha256 -extensions v3_ca -out "certs/${SSLCAFILE}.cert.pem" -subj "/C=$opt_country/ST=$opt_province/L=$opt_city/O=$opt_company/OU=$opt_department/CN=$opt_root_common_name/emailAddress=$opt_email"
  $ECHO chmod 444 "certs/${SSLCAFILE}.cert.pem"

  (( promptnum = promptnum + 1 ))
  echo ""
  echo "$promptnum) verify root certificate"
  $ECHO openssl x509 -noout -text -in "certs/${SSLCAFILE}.cert.pem"

  created_root_ca=yes

  popd > /dev/null
fi

pushd "$SSLCADIR" > /dev/null

newintcaflag=
[ -d "$opt_intermediate_dir" ] || { mkdir -p "$opt_intermediate_dir"; newintcaflag=yes; }

for subdir in certs crl newcerts private csr
do
  [ -d "$opt_intermediate_dir/$subdir" ] || { mkdir "$opt_intermediate_dir/$subdir"; newintcaflag=yes; }
done

if [ -n "$newintcaflag" -o -n "$opt_scrub_intermediate_ca" ]; then
  (( promptnum = promptnum + 1 ))
  echo ""
  echo "$promptnum) generate Intermediate CA certificate"

  pushd "$opt_intermediate_dir" > /dev/null
  
  chmod 700 private
  echo -n "" > index.txt
  echo 1000 > serial
  echo 1000 > crlnumber
  cat > openssl.cnf <<-EOF
    # OpenSSL intermediate CA configuration file.
    # Copy to '$PWD/openssl.cnf'.

    [ ca ]
    # 'man ca'
    default_ca = CA_default

    [ CA_default ]
    # Directory and file locations.
    dir               = $PWD
    certs             = $PWD/certs
    crl_dir           = $PWD/crl
    new_certs_dir     = $PWD/newcerts
    database          = $PWD/index.txt
    serial            = $PWD/serial
    RANDFILE          = $PWD/private/.rand

    # The intermediate CA private key and certificate.
    private_key       = $PWD/private/intermediate.key.pem
    certificate       = $PWD/certs/intermediate.cert.pem

    # For certificate revocation lists.
    crlnumber         = $PWD/crlnumber
    crl               = $PWD/crl/intermediate.crl.pem
    crl_extensions    = crl_ext
    default_crl_days  = 30

    # SHA-1 is deprecated, so use SHA-2 instead.
    default_md        = sha256

    name_opt          = ca_default
    cert_opt          = ca_default
    default_days      = $default_server_cert_expiry
    preserve          = no
    policy            = policy_loose

    [ policy_strict ]
    # The root CA should only sign intermediate certificates that match.
    # See the POLICY FORMAT section of 'man ca'.
    countryName             = match
    stateOrProvinceName     = match
    organizationName        = match
    organizationalUnitName  = optional
    commonName              = supplied
    emailAddress            = optional

    [ policy_loose ]
    # Allow the intermediate CA to sign a more diverse range of certificates.
    # See the POLICY FORMAT section of the 'ca' man page.
    countryName             = optional
    stateOrProvinceName     = optional
    localityName            = optional
    organizationName        = optional
    organizationalUnitName  = optional
    commonName              = supplied
    emailAddress            = optional

    [ req ]
    # Options for the 'req' tool ('man req').
    default_bits        = $opt_bits
    distinguished_name  = req_distinguished_name
    string_mask         = utf8only

    # SHA-1 is deprecated, so use SHA-2 instead.
    default_md          = sha256

    # Extension to add when the -x509 option is used.
    x509_extensions     = v3_ca

    [ req_distinguished_name ]
    # See <https://en.wikipedia.org/wiki/Certificate_signing_request>.
    countryName                     = Country Name (2 letter code)
    stateOrProvinceName             = State or Province Name
    localityName                    = Locality Name
    0.organizationName              = Organization Name
    organizationalUnitName          = Organizational Unit Name
    commonName                      = Common Name
    emailAddress                    = Email Address

    # Optionally, specify some defaults.
    countryName_default             = $opt_country
    stateOrProvinceName_default     = $opt_province
    localityName_default            = $opt_city
    0.organizationName_default      = $opt_company
    organizationalUnitName_default  = $opt_department
    emailAddress_default            = $opt_email

    [ v3_ca ]
    # Extensions for a typical CA ('man x509v3_config').
    subjectKeyIdentifier = hash
    authorityKeyIdentifier = keyid:always,issuer
    basicConstraints = critical, CA:true
    keyUsage = critical, digitalSignature, cRLSign, keyCertSign

    [ v3_intermediate_ca ]
    # Extensions for a typical intermediate CA ('man x509v3_config').
    subjectKeyIdentifier = hash
    authorityKeyIdentifier = keyid:always,issuer
    basicConstraints = critical, CA:true, pathlen:0
    keyUsage = critical, digitalSignature, cRLSign, keyCertSign

    [ usr_cert ]
    # Extensions for client certificates ('man x509v3_config').
    basicConstraints = CA:FALSE
    nsCertType = client, email
    nsComment = "OpenSSL Generated Client Certificate"
    subjectKeyIdentifier = hash
    authorityKeyIdentifier = keyid,issuer
    keyUsage = critical, nonRepudiation, digitalSignature, keyEncipherment
    extendedKeyUsage = clientAuth, emailProtection

    [ server_cert ]
    # Extensions for server certificates ('man x509v3_config').
    basicConstraints = CA:FALSE
    nsCertType = server
    nsComment = "OpenSSL Generated Server Certificate"
    subjectKeyIdentifier = hash
    authorityKeyIdentifier = keyid,issuer:always
    keyUsage = critical, digitalSignature, keyEncipherment
    extendedKeyUsage = serverAuth

    [ crl_ext ]
    # Extension for CRLs ('man x509v3_config').
    authorityKeyIdentifier=keyid:always

    [ ocsp ]
    # Extension for OCSP signing certificates ('man ocsp').
    basicConstraints = CA:FALSE
    subjectKeyIdentifier = hash
    authorityKeyIdentifier = keyid,issuer
    keyUsage = critical, digitalSignature
    extendedKeyUsage = critical, OCSPSigning
EOF

  if [ ".$opt_private_key_cipher" = . ]; then
    (( promptnum = promptnum + 1 ))
    echo ""
    echo "$promptnum) generate $opt_ca_bits intermediate certificate private key for the certificate authority"
    $ECHO openssl genrsa -out private/intermediate.key.pem $opt_ca_bits
  else
    (( promptnum = promptnum + 1 ))
    echo ""
    echo "$promptnum) Generate encrypted $opt_ca_bits bit intermediate certificate private key (a new encryption password will be prompted for)"
    $ECHO openssl genrsa $opt_private_key_cipher -out private/intermediate.key.pem $opt_ca_bits
  fi
  $ECHO chmod 400 private/intermediate.key.pem

  (( promptnum = promptnum + 1 ))
  echo ""
  echo "$promptnum) generate certificate signing request for the intermediate certificate for the certificate authority"
  echo "   Country Name (2 letter code)           : $opt_country"
  echo "   State or Province Name (full name)     : $opt_province"
  echo "   Locality Name (eg, city)               : $opt_city"
  echo "   Organization Name (eg, company)        : $opt_company"
  echo "   Organizational Unit Name (eg, section) : $opt_department"
  echo "   Intermediate Common Name               : $opt_intermediate_common_name"
  echo "   Email Address                          : $opt_email"

  popd > /dev/null

  $ECHO openssl req -config openssl.cnf -new -sha256 -key "$opt_intermediate_dir/private/intermediate.key.pem" -out "$opt_intermediate_dir/csr/intermediate.csr.pem" -subj "/C=$opt_country/ST=$opt_province/L=$opt_city/O=$opt_company/OU=$opt_department/CN=$opt_intermediate_common_name/emailAddress=$opt_email"

  (( promptnum = promptnum + 1 ))
  echo ""
  echo "$promptnum) generate intermediate certificate signed by the root certificate authority"
  [ ".$opt_private_key_cipher" != . ] && { echo ""; echo "the root certificate private key password will be prompted for ..."; }
  $ECHO openssl ca -config openssl.cnf -extensions v3_intermediate_ca -days $twenty_years_of_days -notext -md sha256 -in "$opt_intermediate_dir/csr/intermediate.csr.pem" -out "$opt_intermediate_dir/certs/intermediate.cert.pem"
  $ECHO chmod 444 "$opt_intermediate_dir/certs/intermediate.cert.pem"

  (( promptnum = promptnum + 1 ))
  echo ""
  echo "$promptnum) verify intermediate certificate"
  $ECHO openssl x509 -noout -text -in "$opt_intermediate_dir/certs/intermediate.cert.pem"

  (( promptnum = promptnum + 1 ))
  echo ""
  echo "$promptnum) create the certificate chain"
  cat "$opt_intermediate_dir/certs/intermediate.cert.pem" "certs/${SSLCAFILE}.cert.pem" > "$opt_intermediate_dir/certs/ca-chain.cert.pem"
  $ECHO chmod 444 "$opt_intermediate_dir/certs/ca-chain.cert.pem"

  echo ""
  [ -f "$opt_intermediate_dir/private/${SSLCAFILE}.orig.key.pem" ] && { echo removing "$opt_intermediate_dir/private/${SSLCAFILE}.orig.key.pem"; $ECHO rm "$opt_intermediate_dir/private/${SSLCAFILE}.orig.key.pem"; }
  [ -f "$opt_intermediate_dir/csr/intermediate.csr.pem" ] && { echo removing $opt_intermediate_dir/csr/intermediate.csr.pem; $ECHO rm "$opt_intermediate_dir/csr/intermediate.csr.pem"; }

  created_intermediate_ca=yes
fi
popd > /dev/null

if [ ".$COMMAND" = .trust ]; then
  pushd "$SSLCADIR/$opt_intermediate_dir" > /dev/null

  if [ "$opt_certificate_signing_request_file" ]; then
    $ECHO cp "$opt_certificate_signing_request_file" "csr/${opt_fqdn}.csr.pem"
  else
    if [ ".$opt_private_key_cipher" = . ]; then
      (( promptnum = promptnum + 1 ))
      echo ""
      echo "$promptnum) Generate $opt_bits bit private key (unencrypted)"
      $ECHO openssl genrsa -out "private/${opt_fqdn}.key.pem" $opt_bits
    else
      (( promptnum = promptnum + 1 ))
      echo ""
      echo "$promptnum) Generate encrypted $opt_bits bit private key (encryption password will be prompted for)"
      $ECHO openssl genrsa $opt_private_key_cipher -out "private/${opt_fqdn}.key.pem" $opt_bits
    fi
    $ECHO chmod 700 "private/${opt_fqdn}.key.pem"

    (( promptnum = promptnum + 1 ))
    echo ""
    echo "$prompnum) generate the certificate signing request (csr) for $opt_days days using"
    echo "   Country Name (2 letter code)           : $opt_country"
    echo "   State or Province Name (full name)     : $opt_province"
    echo "   Locality Name (eg, city)               : $opt_city"
    echo "   Organization Name (eg, company)        : $opt_company"
    echo "   Organizational Unit Name (eg, section) : $opt_department"
    echo "   Web Server Fully Qualified Domain Name : $opt_fqdn"
    echo "   Email Address                          : $opt_email"

    [ ".$opt_private_key_cipher" != . ] && { echo ""; echo "$opt_fqdn private key password will be prompted for ..."; }
    $ECHO openssl req -config openssl.cnf -key "private/${opt_fqdn}.key.pem" -new -sha256 -out "csr/${opt_fqdn}.csr.pem" -days $opt_days -subj "/C=$opt_country/ST=$opt_province/L=$opt_city/O=$opt_company/OU=$opt_department/CN=$opt_fqdn/emailAddress=$opt_email"
  fi

  (( promptnum = promptnum + 1 ))
  echo ""
  echo "$promptnum) generate CA signed ssl certificate for $opt_days days"
  $ECHO openssl ca -config openssl.cnf -extensions server_cert -days $opt_days -notext -md sha256 -in "csr/${opt_fqdn}.csr.pem" -out "certs/${opt_fqdn}.cert.pem" 
  $ECHO chmod 444 "certs/${opt_fqdn}.cert.pem" 

  (( promptnum = promptnum + 1 ))
  echo ""
  echo "$promptnum) verify web server certificate"
  $ECHO openssl x509 -noout -text -in "certs/${opt_fqdn}.cert.pem"

  echo ""
  [ -f "private/${opt_fqdn}.orig.key.pem" ] && { echo removing "private/${opt_fqdn}.orig.key.pem"; $ECHO rm "private/${opt_fqdn}.orig.key.pem"; }
  [ -f "csr/${opt_fqdn}.csr.pem" ] && { echo removing "csr/${opt_fqdn}.csr.pem"; $ECHO rm "csr/${opt_fqdn}.csr.pem"; }

  popd > /dev/null

  created_server_cert=yes
fi

if [ "$created_root_ca" ]; then
  echo ""
  echo "root CA private key ${SSLCADIR}/private/${SSLCAFILE}.key.pem"
  echo "root CA certificate ${SSLCADIR}/certs/${SSLCAFILE}.cert.pem"
fi

if [ "$created_intermediate_ca" ]; then
  echo ""
  echo "intermediate CA private key ${SSLCADIR}/$opt_intermediate_dir/private/intermediate.key.pem"
  echo "intermediate CA certificate ${SSLCADIR}/$opt_intermediate_dir/certs/intermediate.cert.pem"
  echo "intermediate CA certificate chain ${SSLCADIR}/$opt_intermediate_dir/certs/ca-chain.cert.pem"
fi

if [ "$created_server_cert" ]; then
  echo ""
  [ "$opt_certificate_signing_request_file" ] ||
    echo "private key ${SSLCADIR}/$opt_intermediate_dir/private/${opt_fqdn}.key.pem"
  echo "public key cert ${SSLCADIR}/$opt_intermediate_dir/certs/${opt_fqdn}.cert.pem"
  echo "certificate chain ${SSLCADIR}/$opt_intermediate_dir/certs/ca-chain.cert.pem"
fi
