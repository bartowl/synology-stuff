# synology-stuff
Collection of potentialy usefull Synology scripts

## reload-certs.sh
This script is meant to be used as --reloadcmd for [acme.sh](https://github.com/acmesh-official/acme.sh).
What it does is - if looks for updated certificates under `/usr/syno/etc/certificate/_archive/xxxxxx` folder
and based on Information from `INFO` file there, rolls out the certificate for appropriate services.
It then reloads only affected services using Synology native mechanismus designed for reloading upon certificate update.
You just need to update the certificate in `_archive`
directory, and this script will do everything that needs to be done for it to be effective. Which serices use which certificates
can be managed normally from Contorl Panel -> Security -> Certificates

## reload-cert-with-import.sh
This script is used to load SSL certificates to synology form external source.
It will also reload all necessery services, based on Synology Settings, when a corresponding certificate changes.
This allows to manage certificates via acme.sh or any other tool, even running in docker container.
I use it to get certificates from within an docker container, which is running an WAF Appliance and push them to synology, so that I can get right certificates when accessing synology locally, without the WAF in path. I use a Docker volume to access the certificates from the container.
