#!/bin/sh
# script to reload synology certificates for all assigned services
# it is meant to be run after renewing certificats to reload all affected services
# for example form acme.sh as --reloadcmd

INFO=/usr/syno/etc/certificate/_archive/INFO
for domain_id in $(jq -r 'keys[]' $INFO); do
  domain=$(jq -r ".$domain_id.desc" $INFO);
  num_services=$(jq -r ".$domain_id.services|length" $INFO)
  src_path=/usr/syno/etc/certificate/_archive/$domain_id

#  echo "domain=$domain ($num_services):"
  for srv_id in $(seq 0 $((num_services-1))); do
    name=$(jq -r ".$domain_id.services[$srv_id].display_name" $INFO)
    service=$(jq -r ".$domain_id.services[$srv_id].service" $INFO)
    subscriber=$(jq -r ".$domain_id.services[$srv_id].subscriber" $INFO)
    isPkg=$(jq -r ".$domain_id.services[$srv_id].isPkg" $INFO)
    if [ "$isPkg" == "true" ]; then
      crtpath=/usr/local/etc/certificate/$subscriber/$service
      reload=/usr/local/libexec/certificate.d/$subscriber
    else
      crtpath=/usr/syno/etc/certificate/$subscriber/$service
      reload=/usr/libexec/certificate.d/$subscriber
    fi
    [ -x "$reload" ] || reload=/bin/true
    # check service CRT gainst src_path
    if ! diff -q $crtpath/cert.pem $src_path/cert.pem > /dev/null; then
      echo "* updating certificate for $name"
      for f in cert.pem chain.pem fullchain.pem privkey.pem; do
        cat $src_path/$f > $crtpath/$f
      done
      ## Work around bug in DSM 6.2.2-24922 Update 4 for system
      if [ "$subscriber" = "system" -a "$service" = "default" ]; then
        if fgrep '[ "$1" = "default" ] && exit' $reload >/dev/null; then
          service="default-bug-workaround"
        fi
      fi
      echo "  reloading..."
      $reload $service > /dev/null
    fi
  done
done
