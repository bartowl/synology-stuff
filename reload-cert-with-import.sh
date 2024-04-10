#!/bin/sh
# script to reload synology certificates from a known location
# feel free to modify "import form WAF" section to point to your location
# script can be run from task scheduler once a day
# normally does not generate any output and returns 0
# if certificates get updated, it prints brief info and returns exit code 1, so a mail notification can be sent

INFO=/usr/syno/etc/certificate/_archive/INFO
exitcode=0
for domain_id in $(jq -r 'keys[]' $INFO); do
  domain=$(jq -r ".$domain_id.desc" $INFO);
  num_services=$(jq -r ".$domain_id.services|length" $INFO)
  src_path=/usr/syno/etc/certificate/_archive/$domain_id

# import from WAF-docker-container start
  import_path=/volume1/docker/WAF/certs/live/$domain
  if ! diff -q $src_path/cert.pem $import_path/cert.pem > /dev/null; then
    echo "* fetched updated cert from WAF container for domain $domain"
    for f in cert.pem chain.pem fullchain.pem privkey.pem; do
      cat $import_path/$f > $src_path/$f
    done
  fi
# import from WAF-docker-container start

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
      echo "* updating certificate for $name [$subscriber:$service ($isPkg)]"
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
      exitcode=1
    fi
  done
done
# fix cert reload for DSM7
if [ $exitcode -eq 1 ]; then
  /usr/syno/bin/synow3tool --gen-all
  synow3tool --restart-dsm-service
fi
exit $exitcode
