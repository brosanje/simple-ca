# simple-ca
Simple Certificate Authority, Root CA, Intermediate CA, self-signed and self-trusted.

Generate SSL certificates.

simple-ca COMMAND \[ Options \] \[ Arguments \]

COMMAND may be

  self-sign - generate a self-signed certificate, with corresponding private key.

  create - create a certificate authority for signing server certs.

  trust - generate the trusted server certificate.

  request - generate a CSR certificate signing request.

Generate a self-signed certificate for a web server.

========================================================

simple-ca self-sign [Options] fully.qualified.server.domain.name

Options
  -bits NUMBER : number of bits in the key (default $opt_bits_default)

  -days NUMBER : number of days to certificate expiry (default $opt_days_default)

  -aes128 -aes192 -aes256 -camellia128 -camellia192 -camellia256
      -des -des3 -idea : type of encryption to use for the private keys.

      default is no encryption, no password.

  -nopassword : no password on the private keys.  this is the default.

  -withpassword : encrypt the private keys, with $opt_private_key_cipher_default_if cipher.

      aliases : -password, -encrypt-private-key

  -country COUNTRY : two letter ISO code for certificate authority country.

      default is $opt_country_default.

  -province PROVINCE : province name for certificate authority.

      default is $opt_province_default.

      alias : -state

  -city CITY : city for certificate authority.

      default is $opt_city_default.

  -company COMPANY : name of certificate authority.

      default is $opt_company_default.

      alias : -organization

  -department DEPARTMENT : department handling certs.

      default is $opt_department_default.

      aliases are -section, -unit

  -email EMAIL : contact email

========================================================

Generate a request for a signed certificate for a web server.

simple-ca request [Options] fully.qualified.server.domain.name

Options
  -bits NUMBER : number of bits in the key (default $opt_bits_default)
  -days NUMBER : number of days to certificate expiry (default $opt_days_default)
  -aes128 -aes192 -aes256 -camellia128 -camellia192 -camellia256
      -des -des3 -idea : type of encryption to use for the private keys.
      default is no encryption, no password.
  -nopassword : no password on the private keys.  this is the default.
  -withpassword : encrypt the private keys, with $opt_private_key_cipher_default_if cipher.
      aliases : -password, -encrypt-private-key
  -country COUNTRY : two letter ISO code for certificate authority country.
      default is $opt_country_default.
  -province PROVINCE : province name for certificate authority.
      default is $opt_province_default.
      alias : -state
  -city CITY : city for certificate authority.
      default is $opt_city_default.
  -company COMPANY : name of certificate authority.
      default is $opt_company_default.
      alias : -organization
  -department DEPARTMENT : department handling certs.
      default is $opt_department_default.
      aliases are -section, -unit
  -email EMAIL : contact email

========================================================

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
    the Intermediate CA data.  default is $opt_intermediate_dir_default.
  -bits NUMBER : number of bits in the key (default $opt_bits_default)
  -years NUMBER : default number of years to certificate
      expiry (default $opt_years_default)
  -days NUMBER : number of days to certificate expiry (default $opt_days_default)
  -aes128 -aes192 -aes256 -camellia128 -camellia192 -camellia256
      -des -des3 -idea : type of encryption to use for the private keys.
      default is no encryption, no password.
  -nopassword : no password on the private keys.  this is the default.
  -withpassword : encrypt the private keys, with $opt_private_key_cipher_default_if cipher.
      aliases : -password, -encrypt-private-key
  -country COUNTRY : two letter ISO code for certificate authority country.
      default is $opt_country_default.
  -province PROVINCE : province name for certificate authority.
      default is $opt_province_default.
      alias : -state
  -city CITY : city for certificate authority.
      default is $opt_city_default.
  -company COMPANY : name of certificate authority.
      default is $opt_company_default.
      alias : -organization
  -department DEPARTMENT : department handling certs.
      default is $opt_department_default.
      aliases are -section, -unit
  -email EMAIL : contact email

========================================================

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
  the Intermediate CA data.  default is $opt_intermediate_dir_default.

IntermediateCommonName
  Optional common name for the Intermediate Certificate Authority.
  default is $opt_intermediate_common_name_default.

Options
  -new : create CA as new.  if CA exists, scrub it.
  -new-intermediate : create Intermediate CA as new.  if it exists, scrub it.
  -bits NUMBER : number of bits in the key (default $opt_bits_default)
  -years NUMBER : default number of years to certificate
      expiry (default $opt_years_default)
  -aes128 -aes192 -aes256 -camellia128 -camellia192 -camellia256
      -des -des3 -idea : type of encryption to use for the private keys.
      default is no encryption, no password.
  -nopassword : no password on the private keys.  this is the default.
  -withpassword : encrypt the private keys, with $opt_private_key_cipher_default_if cipher.
      aliases : -password, -encrypt-private-key
  -country COUNTRY : two letter ISO code for certificate authority country.
      default is $opt_country_default.
  -province PROVINCE : province name for certificate authority.
      default is $opt_province_default.
      alias : -state
  -city CITY : city for certificate authority.
      default is $opt_city_default.
  -company COMPANY : name of certificate authority.
      default is $opt_company_default.
      alias : -organization
  -department DEPARTMENT : department handling certs.
      default is $opt_department_default.
      aliases are -section, -unit
  -email EMAIL : contact email

