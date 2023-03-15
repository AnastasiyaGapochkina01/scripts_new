#!/bin/bash
LOC=$1

charts=$(ssh ${LOC}-controller curl -s localhost:9192/clusters | jq ' .clusters | keys | .[]' | cut -d\" -f 2 | grep "$LOC-charts-*")
other_charts=$(ssh ${LOC}-controller curl -s localhost:9192/hosts | jq '.hosts | keys | .[]' | cut -d\" -f 2 | grep -E "cme|bovespa|mobile")

charts_hosts=()

for c in $charts; do
  host=$(echo $c | sed 's/charts/compute/g' | sed 's/-wgt//g')
  charts_hosts+=("$host")
done

hosts="${charts_hosts[@]} $other_charts"

out=()

for h in $hosts; do
  ssh -o UserKnownHostsFile=/dev/null \
      -o StrictHostKeyChecking=no \
      -o LogLevel=quiet $h 'for c in $(sudo docker ps -a -q --filter "name=-metrix"); do sudo docker exec $c /bin/bash -l -c "printenv FACTER_cluster_id FACTER_config_name DOCKER_IMAGE"; done' >>  ./charts_${LOC}

done

./charts_v3.py ./charts_${LOC}
rm -f ./charts_${LOC}
