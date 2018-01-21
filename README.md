# simple-ca

## Synopsis

A shell script implementing a simple certificate authority, with the ability to

* generate self-signed certificates.
* create a certificate authority.
* generate certificates trusted by the certificate authority.
* generate requests, a CSR certificate signing request you can send to a real certificate authority.
* show what's in a certificate.

## Guides

Helpful sources.

* [How to setup your own CA with OpenSSL](https://gist.github.com/Soarez/9688998)
* [HOWTO: Creating SSL certificates with CAcert.org and OpenSSL](http://www.lwithers.me.uk/articles/cacert.html)
* [Generating client certificates with Subject Alternate Names (SAN)](https://support.ca.com/us/knowledge-base-articles.TEC0000001288.html)

## Usage
```
Help

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

========================================================

Generate a self-signed certificate for a web server.

simple-ca [-nox | -t] self-sign [Options] fully.qualified.server.domain.name

Options
  -bits NUMBER : number of bits in the key (default 2048)
  -days NUMBER : number of days to certificate expiry (default 365)
  -aes128 -aes192 -aes256 -camellia128 -camellia192 -camellia256
      -des -des3 -idea : type of encryption to use for the private keys.
      default is no encryption, no password.
  -nopassword : no password on the private keys.  this is the default.
  -withpassword : encrypt the private keys, with aes256 cipher.
      aliases : -password, -encrypt-private-key
  -country COUNTRY : two letter ISO code for certificate authority country.
      default is none.
  -province PROVINCE : province name for certificate authority.
      default is none.
      alias : -state
  -city CITY : city for certificate authority.
      default is none.
  -company COMPANY : name of certificate authority.
      default is none.
      alias : -organization
  -department DEPARTMENT : department handling certs.
      default is none.
      aliases are -section, -unit
  -email EMAIL : contact email

========================================================

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
  the Intermediate CA data.  default is intermediate.

IntermediateCommonName
  Optional common name for the Intermediate Certificate Authority.
  default is none.

Options
  -new : create CA as new.  if CA exists, scrub it.
  -new-intermediate : create Intermediate CA as new.  if it exists, scrub it.
  -bits NUMBER : number of bits in the key (default 2048)
  -years NUMBER : default number of years to certificate
      expiry (default 1)
  -aes128 -aes192 -aes256 -camellia128 -camellia192 -camellia256
      -des -des3 -idea : type of encryption to use for the private keys.
      default is no encryption, no password.
  -nopassword : no password on the private keys.  this is the default.
  -withpassword : encrypt the private keys, with aes256 cipher.
      aliases : -password, -encrypt-private-key
  -country COUNTRY : two letter ISO code for certificate authority country.
      default is none.
  -province PROVINCE : province name for certificate authority.
      default is none.
      alias : -state
  -city CITY : city for certificate authority.
      default is none.
  -company COMPANY : name of certificate authority.
      default is none.
      alias : -organization
  -department DEPARTMENT : department handling certs.
      default is none.
      aliases are -section, -unit
  -email EMAIL : contact email

========================================================

Generate trusted certificates for a web server, using the configured
Certificate Authority, or generating one on the fly, so that a trusted
server certificate chain can be created.

simple-ca [ -t | -nox ] trust [Options] fully.qualified.server.domain.name

If a root Certificate Authority is found in ssl/certificate-authority, and an
intermediate Certificate Authority is found, then those will be
used to generate the trusted certificate chain.  Otherwise, they
will be created.

Options
  -new : create CA as new.  if CA exists, scrub it.
  -new-intermediate : create Intermediate CA as new.  if it exists, scrub it.
  -intermediate INTERMEDIATE-DIRECTORY : Intermediate CA to use.
    Optional name of directory within the CA directory to hold
    the Intermediate CA data.  default is intermediate.
  -bits NUMBER : number of bits in the key (default 2048)
  -years NUMBER : default number of years to certificate
      expiry (default 1)
  -days NUMBER : number of days to certificate expiry (default 365)
  -aes128 -aes192 -aes256 -camellia128 -camellia192 -camellia256
      -des -des3 -idea : type of encryption to use for the private keys.
      default is no encryption, no password.
  -nopassword : no password on the private keys.  this is the default.
  -withpassword : encrypt the private keys, with aes256 cipher.
      aliases : -password, -encrypt-private-key
  -country COUNTRY : two letter ISO code for certificate authority country.
      default is none.
  -province PROVINCE : province name for certificate authority.
      default is none.
      alias : -state
  -city CITY : city for certificate authority.
      default is none.
  -company COMPANY : name of certificate authority.
      default is none.
      alias : -organization
  -department DEPARTMENT : department handling certs.
      default is none.
      aliases are -section, -unit
  -email EMAIL : contact email.
  -ip IP-NUMBER : an alternate name for the server.
  -reset : if the common name has already been defined, delete it from the database.

========================================================

Generate a request for a signed certificate for a web server.

simple-ca [ -t | -nox ] request [Options] fully.qualified.server.domain.name

Options
  -bits NUMBER : number of bits in the key (default 2048)
  -days NUMBER : number of days to certificate expiry (default 365)
  -aes128 -aes192 -aes256 -camellia128 -camellia192 -camellia256
      -des -des3 -idea : type of encryption to use for the private keys.
      default is no encryption, no password.
  -nopassword : no password on the private keys.  this is the default.
  -withpassword : encrypt the private keys, with aes256 cipher.
      aliases : -password, -encrypt-private-key
  -country COUNTRY : two letter ISO code for certificate authority country.
      default is none.
  -province PROVINCE : province name for certificate authority.
      default is none.
      alias : -state
  -city CITY : city for certificate authority.
      default is none.
  -company COMPANY : name of certificate authority.
      default is none.
      alias : -organization
  -department DEPARTMENT : department handling certs.
      default is none.
      aliases are -section, -unit
  -email EMAIL : contact email

========================================================

Show info for the named certificate.

simple-ca [-nox | -t] verify path-to-certificate-file
```
