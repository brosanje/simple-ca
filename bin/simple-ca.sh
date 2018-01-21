#!/bin/bash

${TraceF-}

# commands
# self-sign
# create
# trust
# request
# verify
# help

###############
## defaults
: ${SSLDIR:=ssl}
: ${SSLCADIR:=$SSLDIR/certificate-authority}
: ${SSLFILE:=server}
: ${SSLCAFILE:=ca}
: ${APACHE_RUN_GROUP:=www-data} ## see /etc/apache2/envvars

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
## constants
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

cleanup_sh() {
	${TraceF:-:}
	typeset fn objtype objname deleted=
	
	runshcmd rm -f "${TMP:-nonexistantfile}"*
	
	for fn in $CLEANUP
	do
		case "$deleted" in
		*,"$fn",*|*,"$fn"|"$fn",*) continue ;;
		esac
		
    runshcmd rm -f "$fn"
		
		deleted="${deleted}${deleted:+,}$fn"
	done
}

runshcmd() {
  [ -n "${TraceF-}" ] && ${TraceF-}
  typeset input output ec=0
  
  if [ ".$1" = ".-o" ]; then
    output="$2"
    shift
    shift
    if [ ."${ECHO-}" = .echo ]; then
      echo "$* > $output" >&2
    elif [ ."${ECHO-}" = .trace ]; then
      echo "$* > $output" >&2
      "$@" > "$output"; ec=$?
    else
      "$@" > "$output"; ec=$?
    fi
  elif [ ".$1" = ".-i" ]; then
    input="$2"
    shift
    shift
    if [ ."${ECHO-}" = .echo ]; then
      echo "$* < $input" >&2
    elif [ ."${ECHO-}" = .trace ]; then
      echo "$* < $input" >&2
      "$@" < "$input"; ec=$?
    else
      "$@" < "$input"; ec=$?
    fi
  else
    if [ ."${ECHO-}" = .echo ]; then
      echo "$*" >&2
    elif [ ."${ECHO-}" = .trace ]; then
      echo "$*" >&2
      "$@"; ec=$?
    else
      "$@"; ec=$?
    fi
  fi
  return $ec
}

###############
## usage
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
[Hh]elp|all)
  cat <<EOF

Generate SSL certificates.

simple-ca [ -nox | -x | -t ] COMMAND [ Options ] [ Arguments ]

  -x (default) execute shell commands, don't echo.
  -nox don't execute shell commands, just echo.
  -t trace (echo) shell commands and execute them.

COMMAND may be

  self-sign - generate a self-signed certificate, with corresponding private key.
  create - create a certificate authority for signing server certs.
  trust - generate the trusted server certificate.
  request - generate a CSR certificate signing request.
  verify - display info on a named certificate.
  help - show help

EOF
  ;;
esac

case "$COMMAND" in
all) echo -e '\n========================================================' ;;
esac

case "$COMMAND" in
self-sign|all)
  cat <<EOF

Generate a self-signed certificate for a web server.

simple-ca [-nox | -t] self-sign [Options] fully.qualified.server.domain.name

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
esac

case "$COMMAND" in
all) echo -e '\n========================================================' ;;
esac

case "$COMMAND" in
create|all)
  cat <<EOF

Create a Certificate Authority for generating free https certificates

simple-ca [ -t | -nox ] create [Options] [ IntermediateDirectory [ IntermediateCommonName ] ]

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
  default is ${opt_intermediate_common_name_default:-none}.

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
esac

case "$COMMAND" in
all) echo -e '\n========================================================' ;;
esac

case "$COMMAND" in
trust|all)
  cat <<EOF

Generate trusted certificates for a web server, using the configured
Certificate Authority, or generating one on the fly, so that a trusted
server certificate chain can be created.

simple-ca [ -t | -nox ] trust [Options] fully.qualified.server.domain.name

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
  -email EMAIL : contact email.
  -ip IP-NUMBER : an alternate name for the server.
  -reset : if the common name has already been defined, delete it from the database.
EOF
  ;;
esac

case "$COMMAND" in
all) echo -e '\n========================================================' ;;
esac

case "$COMMAND" in
request|all)
  cat <<EOF

Generate a request for a signed certificate for a web server.

simple-ca [ -t | -nox ] request [Options] fully.qualified.server.domain.name

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
esac

case "$COMMAND" in
all) echo -e '\n========================================================' ;;
esac

case "$COMMAND" in
verify|all)
  cat <<EOF

Show info for the named certificate.

simple-ca [-nox | -t] verify path-to-certificate-file

EOF
  ;;
esac

  [ -n "$exitcode" ] && exit $exitcode
}

###############
## main
TMP=/tmp/simple-ca-$$
trap cleanup_sh EXIT

#######################################
## parse command line
while [ $# -gt 0 ]
do
  case "$1" in
  -x|-execute) ECHO=; shift ;;
  -t|-trace) ECHO=trace; shift ;;
  -nox|-noexecute) ECHO=echo; shift ;;
  --) shift; break ;;
  '-?') usage -exit 0 Help ;;
  -*) usage -exit 1 "Invalid option $1" >&2 ;;
  *) break ;;
  esac
done

case "$1" in
self-sign) COMMAND=self-sign; shift ;;
create) COMMAND=create; shift ;;
trust) COMMAND=trust; shift ;;
request) COMMAND=request; shift ;;
verify) COMMAND=verify; shift ;;
help) COMMAND=${2:-help}; usage -exit 0 "Help" ;;
*) usage -exit 1 "Invalid command $1" >&2 ;;
esac

##
## parse command options
##
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
  -san_ip|-ip) san_ip=$2; shift; shift ;;
  -reset) reset_server_certificate=yes; shift ;;
  -email) opt_email=$2; shift; shift ;;
  --) shift; break ;;
  '-?') usage -exit 0 Help ;;
  -*) usage -exit 1 "Invalid option $1" >&2 ;;
  *) break ;;
  esac
done

#######################################
## prompt for missing info
case "$COMMAND" in
verify)
  opt_certificate_signing_request_file=$(readlink -f "$1")
  ;;

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

#######################################
## prepare
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

#######################################
## prompt for missing info
if [ ".$COMMAND" != .verify ]; then
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
fi

stagenum=0

#######################################
## execute
case "$COMMAND" in
self-sign)
  echo ""
  echo "Generate a self-signed certificate"

  keyfile="${SSLDIR}/${SSLFILE}.key.pem"
  [ -e "$keyfile" -a ! -w "$keyfile" ] && runshcmd chmod u+w "$keyfile"

  if [ ".$opt_private_key_cipher" = . ]; then
    (( stagenum = stagenum + 1 ))
    echo ""
    echo "$stagenum) Generate $opt_bits bit private key (unencrypted)"
    runshcmd openssl genrsa -out "$keyfile" $opt_bits
  else
    (( stagenum = stagenum + 1 ))
    echo ""
    echo "$stagenum) Generate encrypted $opt_bits bit private key (encryption password will be prompted for)"
    runshcmd openssl genrsa $opt_private_key_cipher -out "$keyfile" $opt_bits
  fi
  runshcmd chmod 440 "$keyfile"
  [ "$APACHE_RUN_GROUP" ] && runshcmd chgrp ${APACHE_RUN_GROUP} "$keyfile"

  (( stagenum = stagenum + 1 ))
  echo ""
  echo "$stagenum) generate the certificate signing request (csr) for $opt_days days using"
  echo "   Country Name (2 letter code)           : $opt_country"
  echo "   State or Province Name (full name)     : $opt_province"
  echo "   Locality Name (eg, city)               : $opt_city"
  echo "   Organization Name (eg, company)        : $opt_company"
  echo "   Organizational Unit Name (eg, section) : $opt_department"
  echo "   Web Server Fully Qualified Domain Name : $opt_fqdn"
  echo "   Email Address                          : $opt_email"

  [ ".$opt_private_key_cipher" != . ] && { echo ""; echo "private key password will be prompted for ..."; }
    {
      sed -e 's/^  *//' <<EOF
        [req]
        default_bits = 2048
        prompt = no
        default_md = sha256
        req_extensions = SAN
        distinguished_name = dn

        [ dn ]
        C=$opt_country
        ST=$opt_province
        L=$opt_city
        O=$opt_company
        OU=$opt_department
        emailAddress=$opt_email
        CN=$opt_fqdn

        [ SAN ]
        subjectAltName = @alt_names

        [ alt_names ]
        DNS.1   = $opt_fqdn
        email.2 = copy
EOF
      [ -n "$san_ip" ] && echo "IP.3    = $san_ip"
    } > "${TMP}_selfsigned"

  runshcmd openssl req -new -sha256 -key "${SSLDIR}/${SSLFILE}.key.pem" -out "${SSLDIR}/${SSLFILE}.csr.pem" -days $opt_days -config "${TMP}_selfsigned"

  (( stagenum = stagenum + 1 ))
  echo ""
  echo "$stagenum) generate self signed ssl certificate for $opt_days days"
  runshcmd openssl x509 -req -days $opt_days -in "${SSLDIR}/${SSLFILE}.csr.pem" -signkey "${SSLDIR}/${SSLFILE}.key.pem" -out "${SSLDIR}/${SSLFILE}.cert.pem"
  runshcmd chmod 444 "${SSLDIR}/${SSLFILE}.cert.pem"

  (( stagenum = stagenum + 1 ))
  echo ""
  echo "$stagenum) verify certificate"
  runshcmd openssl x509 -noout -text -in "${SSLDIR}/${SSLFILE}.cert.pem"

  echo ""
  [ -f "${SSLDIR}/${SSLFILE}.orig.key.pem" ] && { echo removing "${SSLDIR}/${SSLFILE}.orig.key.pem"; runshcmd rm "${SSLDIR}/${SSLFILE}.orig.key.pem"; }
  [ -f "${SSLDIR}/${SSLFILE}.csr.pem" ] && { echo removing "${SSLDIR}/${SSLFILE}.csr.pem"; runshcmd rm "${SSLDIR}/${SSLFILE}.csr.pem"; }

  echo ""
  echo "self-signed private key ${SSLDIR}/${SSLFILE}.key.pem"
  echo "self-signed certificate ${SSLDIR}/${SSLFILE}.cert.pem"

  exit 0
  ;;

verify)
  echo ""
  echo "Verifying a certificate ..."
  echo ""

  runshcmd openssl x509 -noout -text -in "$opt_certificate_signing_request_file"
  exit $?
  ;;

request)
  echo ""
  echo "Generating a request for a (Real) Certificate Authority to sign"

  keyfile="${SSLDIR}/${opt_fqdn}.key.pem"
  [ -e "$keyfile" -a ! -w "$keyfile" ] && runshcmd chmod u+w "$keyfile"

  if [ ".$opt_private_key_cipher" = . ]; then
    (( stagenum = stagenum + 1 ))
    echo ""
    echo "$stagenum) Generate $opt_bits bit private key (unencrypted)"
    runshcmd openssl genrsa -out "$keyfile" $opt_bits
  else
    (( stagenum = stagenum + 1 ))
    echo ""
    echo "$stagenum) Generate encrypted $opt_bits bit private key (encryption password will be prompted for)"
    runshcmd openssl genrsa $opt_private_key_cipher -out "$keyfile" $opt_bits
  fi
  runshcmd chmod 440 "$keyfile"
  [ "$APACHE_RUN_GROUP" ] && runshcmd chgrp ${APACHE_RUN_GROUP} "$keyfile"

  (( stagenum = stagenum + 1 ))
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
  runshcmd openssl req -key "${SSLDIR}/${opt_fqdn}.key.pem" -new -sha256 -out "${SSLDIR}/${opt_fqdn}.csr.pem" -days $opt_days -subj "/C=$opt_country/ST=$opt_province/L=$opt_city/O=$opt_company/OU=$opt_department/CN=$opt_fqdn/emailAddress=$opt_email/subjectAltName=DNS:$opt_fqdn,email:copy"

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
  echo ""
  echo "Generating a Certificate Authority in $SSLCADIR"

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

  keyfile="private/${SSLCAFILE}.key.pem"
  [ -e "$keyfile" -a ! -w "$keyfile" ] && runshcmd chmod u+w "$keyfile"

  if [ ".$opt_private_key_cipher" = . ]; then
    (( stagenum = stagenum + 1 ))
    echo ""
    echo "$stagenum) Generate $opt_ca_bits bit root certificate authority private key (unencrypted)"
    runshcmd openssl genrsa -out "$keyfile" $opt_ca_bits
  else
    (( stagenum = stagenum + 1 ))
    echo ""
    echo "$stagenum) Generate encrypted $opt_ca_bits bit root certificate authority private key (encryption password will be prompted for)"
    runshcmd openssl genrsa $opt_private_key_cipher -out "$keyfile" $opt_ca_bits
  fi
  runshcmd chmod 440 "$keyfile"
  [ "$APACHE_RUN_GROUP" ] && runshcmd chgrp ${APACHE_RUN_GROUP} "$keyfile"

  (( stagenum = stagenum + 1 ))
  echo ""
  echo "$stagenum) generate the root certificate with expiry in 20 years ($twenty_years_of_days days) using"
  echo "   Country Name (2 letter code)           : $opt_country"
  echo "   State or Province Name (full name)     : $opt_province"
  echo "   Locality Name (eg, city)               : $opt_city"
  echo "   Organization Name (eg, company)        : $opt_company"
  echo "   Organizational Unit Name (eg, section) : $opt_department"
  echo "   CA Common Name                         : $opt_root_common_name"
  echo "   Email Address                          : $opt_email"

  [ ".$opt_private_key_cipher" != . ] && { echo ""; echo "the root certificate private key password will be prompted for ..."; }
  runshcmd openssl req -config openssl.cnf -key "private/${SSLCAFILE}.key.pem" -new -x509 -days $twenty_years_of_days -sha256 -extensions v3_ca -out "certs/${SSLCAFILE}.cert.pem" -subj "/C=$opt_country/ST=$opt_province/L=$opt_city/O=$opt_company/OU=$opt_department/CN=$opt_root_common_name/emailAddress=$opt_email"
  runshcmd chmod 444 "certs/${SSLCAFILE}.cert.pem"

  (( stagenum = stagenum + 1 ))
  echo ""
  echo "$stagenum) verify root certificate"
  runshcmd openssl x509 -noout -text -in "certs/${SSLCAFILE}.cert.pem"

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
  echo ""
  echo "Generating an Cartificate Authority Intermediate"

  (( stagenum = stagenum + 1 ))
  echo ""
  echo "$stagenum) generate Intermediate CA certificate"

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

  keyfile=private/intermediate.key.pem
  [ -e "$keyfile" -a ! -w "$keyfile" ] && runshcmd chmod u+w "$keyfile"

  if [ ".$opt_private_key_cipher" = . ]; then
    (( stagenum = stagenum + 1 ))
    echo ""
    echo "$stagenum) generate $opt_ca_bits intermediate certificate private key for the certificate authority"
    runshcmd openssl genrsa -out "$keyfile" $opt_ca_bits
  else
    (( stagenum = stagenum + 1 ))
    echo ""
    echo "$stagenum) Generate encrypted $opt_ca_bits bit intermediate certificate private key (a new encryption password will be prompted for)"
    runshcmd openssl genrsa $opt_private_key_cipher -out "$keyfile" $opt_ca_bits
  fi
  runshcmd chmod 440 "$keyfile"
  [ "$APACHE_RUN_GROUP" ] && runshcmd chgrp ${APACHE_RUN_GROUP} "$keyfile"

  (( stagenum = stagenum + 1 ))
  echo ""
  echo "$stagenum) generate certificate signing request for the intermediate certificate for the certificate authority"
  echo "   Country Name (2 letter code)           : $opt_country"
  echo "   State or Province Name (full name)     : $opt_province"
  echo "   Locality Name (eg, city)               : $opt_city"
  echo "   Organization Name (eg, company)        : $opt_company"
  echo "   Organizational Unit Name (eg, section) : $opt_department"
  echo "   Intermediate Common Name               : $opt_intermediate_common_name"
  echo "   Email Address                          : $opt_email"

  popd > /dev/null

  runshcmd openssl req -config openssl.cnf -new -sha256 -key "$opt_intermediate_dir/private/intermediate.key.pem" -out "$opt_intermediate_dir/csr/intermediate.csr.pem" -subj "/C=$opt_country/ST=$opt_province/L=$opt_city/O=$opt_company/OU=$opt_department/CN=$opt_intermediate_common_name/emailAddress=$opt_email"

  certfile="$opt_intermediate_dir/certs/intermediate.cert.pem"
  [ -e "$certfile" -a ! -w "$certfile" ] && runshcmd chmod u+w "$certfile"

  (( stagenum = stagenum + 1 ))
  echo ""
  echo "$stagenum) generate intermediate certificate signed by the root certificate authority"
  [ ".$opt_private_key_cipher" != . ] && { echo ""; echo "the root certificate private key password will be prompted for ..."; }
  runshcmd openssl ca -config openssl.cnf -extensions v3_intermediate_ca -days $twenty_years_of_days -notext -md sha256 -in "$opt_intermediate_dir/csr/intermediate.csr.pem" -out "$certfile"
  runshcmd chmod 444 "$certfile"

  (( stagenum = stagenum + 1 ))
  echo ""
  echo "$stagenum) verify intermediate certificate"
  runshcmd openssl x509 -noout -text -in "$certfile"

  (( stagenum = stagenum + 1 ))
  echo ""
  echo "$stagenum) create the certificate chain"
  cat "$certfile" "certs/${SSLCAFILE}.cert.pem" > "$opt_intermediate_dir/certs/ca-chain.cert.pem"
  runshcmd chmod 444 "$opt_intermediate_dir/certs/ca-chain.cert.pem"

  echo ""
  [ -f "$opt_intermediate_dir/private/${SSLCAFILE}.orig.key.pem" ] && { echo removing "$opt_intermediate_dir/private/${SSLCAFILE}.orig.key.pem"; runshcmd rm "$opt_intermediate_dir/private/${SSLCAFILE}.orig.key.pem"; }
  [ -f "$opt_intermediate_dir/csr/intermediate.csr.pem" ] && { echo removing $opt_intermediate_dir/csr/intermediate.csr.pem; runshcmd rm "$opt_intermediate_dir/csr/intermediate.csr.pem"; }

  created_intermediate_ca=yes
fi
popd > /dev/null

if [ ".$COMMAND" = .trust ]; then
  echo ""
  echo "Generate a trusted server certificate for $opt_fqdn"

  pushd "$SSLCADIR/$opt_intermediate_dir" > /dev/null

  if [ -f index.txt ]; then
    if grep -q "$opt_fqdn" index.txt; then
      if [ ".$reset_server_certificate" = .yes ]; then
        echo "$opt_fqdn certificate has already been built - reset specified, removing from database"
        runshcmd sed -e "/$opt_fqdn/d" < index.txt > "${TMP}_updated_index"
        runshcmd cp "${TMP}_updated_index" index.txt
      else
        echo "$opt_fqdn certificate has already been built - reset was not specified, cannot replace the certificate"
        exit 1
      fi
    fi
  fi

  if [ "$opt_certificate_signing_request_file" ]; then
    runshcmd cp "$opt_certificate_signing_request_file" "csr/${opt_fqdn}.csr.pem"
  else
    keyfile="private/${opt_fqdn}.key.pem"
    [ -e "$keyfile" -a ! -w "$keyfile" ] && runshcmd chmod u+w "$keyfile"

    if [ ".$opt_private_key_cipher" = . ]; then
      (( stagenum = stagenum + 1 ))
      echo ""
      echo "$stagenum) Generate $opt_bits bit private key (unencrypted)"
      runshcmd openssl genrsa -out "$keyfile" $opt_bits
    else
      (( stagenum = stagenum + 1 ))
      echo ""
      echo "$stagenum) Generate encrypted $opt_bits bit private key (encryption password will be prompted for)"
      runshcmd openssl genrsa $opt_private_key_cipher -out "$keyfile" $opt_bits
    fi
    runshcmd chmod 440 "$keyfile"
    [ "$APACHE_RUN_GROUP" ] && runshcmd chgrp ${APACHE_RUN_GROUP} "$keyfile"

    (( stagenum = stagenum + 1 ))
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

    {
      cat openssl.cnf

      sed -e 's/^  *//' <<EOF
        [ SAN ]
        subjectAltName = @alt_names

        [ alt_names ]
        DNS.1   = $opt_fqdn
        email.2 = copy
EOF
      [ -n "$san_ip" ] && echo "IP.3    = $san_ip"
    } > ${TMP}_req_extensions.cnf

    runshcmd openssl req -key "private/${opt_fqdn}.key.pem" -new -sha256 -out "csr/${opt_fqdn}.csr.pem" -days $opt_days -subj "/C=$opt_country/ST=$opt_province/L=$opt_city/O=$opt_company/OU=$opt_department/CN=$opt_fqdn/emailAddress=$opt_email" -reqexts SAN -config ${TMP}_req_extensions.cnf
  fi

  certfile="certs/${opt_fqdn}.cert.pem" 
  [ -e "$certfile" -a ! -w "$certfile" ] && runshcmd chmod u+w "$certfile"

  {
    sed -e 's/^  *//' <<EOF
      # Extensions for server certificates ('man x509v3_config').
      [ SAN ]
      nsCertType = server
      subjectAltName = @salt_names
      basicConstraints = CA:FALSE
      nsComment = "OpenSSL Generated Server Certificate"
      subjectKeyIdentifier = hash
      authorityKeyIdentifier = keyid,issuer:always
      keyUsage = critical, digitalSignature, keyEncipherment
      extendedKeyUsage = serverAuth

      [ salt_names ]
      DNS.1   = $opt_fqdn
      email.2 = copy
EOF
    [ -n "$san_ip" ] && echo "IP.3    = $san_ip"
  } > "${TMP}_ca_server_extfile"

  (( stagenum = stagenum + 1 ))
  echo ""
  echo "$stagenum) generate CA signed ssl certificate for $opt_days days"
  runshcmd openssl ca -config openssl.cnf -extensions SAN -extfile "${TMP}_ca_server_extfile" -days $opt_days -notext -md sha256 -in "csr/${opt_fqdn}.csr.pem" -out "$certfile"
  runshcmd chmod 444 "$certfile" 

  (( stagenum = stagenum + 1 ))
  echo ""
  echo "$stagenum) verify web server certificate"
  runshcmd openssl x509 -noout -text -in "$certfile"

  echo ""
  [ -f "private/${opt_fqdn}.orig.key.pem" ] && { echo removing "private/${opt_fqdn}.orig.key.pem"; runshcmd rm "private/${opt_fqdn}.orig.key.pem"; }
  [ -f "csr/${opt_fqdn}.csr.pem" ] && { echo removing "csr/${opt_fqdn}.csr.pem"; runshcmd rm "csr/${opt_fqdn}.csr.pem"; }

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
