# synology-stuff
Collection of potentialy usefull Synology scripts

## cert-reload.sh
This script is used to externally push SSL certificates to synology.
It is aimed to reload all necessery services, based on Synology Settings, when a corresponding certificate changes.
This allows to manage certificates via acme.sh or any other tool, even running in docker container.
I use it to get certificates from within an docker container, which is running an WAF Appliance and push them to synology, so that I can get right certificates when accessing synology locally, without the WAF in path.
