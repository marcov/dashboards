#!/bin/bash
#
#
#
set -euo pipefail

declare -r scriptStarted="/tmp/run-sh-started"
declare -r scriptCompleted="/tmp/run-sh-completed"

rm -f "$scriptCompleted"
touch "$scriptStarted"

declare -r scriptPath="$(readlink -e $0)"
declare -r scriptDir="$(dirname "${scriptPath}")"

declare  -r realtimeJsonConfig="realtime-json.yml"
set -x

# Stop everything
docker stop `docker ps -a -q` 2>/dev/null || { echo "No containers to stop"; }

docker run \
	--rm -d \
	-v "${scriptDir}"/nginx-default.conf:/etc/nginx/conf.d/default.conf \
        -v "${scriptDir}"/html:/usr/share/nginx/html \
	--publish 80:80 --publish 3000:3000 --publish 9090:9090 \
	--name=nginx \
	nginx \

docker run --rm -d \
        -v grafana-storage:/var/lib/grafana -v "${scriptDir}"/grafana.ini:/etc/grafana/grafana.ini \
	--network=container:nginx \
	--name=grafana \
	grafana/grafana \

docker run --rm -d \
        -v prometheus:/prometheus -v "${scriptDir}"/prometheus.yml:/etc/prometheus/prometheus.yml \
	--network=container:nginx \
	--name=prom \
	prom/prometheus \
	\
	--config.file=/etc/prometheus/prometheus.yml \
	--storage.tsdb.path=/prometheus \
	--web.enable-admin-api

docker run \
	--rm -d \
	-v "${scriptDir}/${realtimeJsonConfig}":/config.yml \
	--network=container:nginx \
	--name=json_fiobbio \
	quay.io/prometheuscommunity/json-exporter \
	\
	--port 7979 http://meteo.fiobbio.com/realtime.json /config.yml \

docker run \
	--rm -d \
	-v "${scriptDir}/${realtimeJsonConfig}":/config.yml \
	--network=container:nginx \
	--name=json_misma \
	quay.io/prometheuscommunity/json-exporter \
	\
	--port 7980 http://meteo.fiobbio.com/misma/realtime.json /config.yml \

docker run \
	--rm -d \
	-v "${scriptDir}/${realtimeJsonConfig}":/config.yml \
	--network=container:nginx \
	--name=json_villa \
	quay.io/prometheuscommunity/json-exporter \
	\
	--port 7990 http://villameteo.fiobbio.com/weather/realtime.json /config.yml \

docker run \
	--rm -d \
	-v "${scriptDir}"/home-cancel.yml:/config.yml \
	--network=container:nginx \
	--name=json_home \
	quay.io/prometheuscommunity/json-exporter \
	\
	--port 7981 http://jak.sba.lat/cancel/jsonData /config.yml \

docker run \
	--rm -d \
  	-v "/:/host:ro,rslave" \
  	--pid=host \
	--network=container:nginx \
	--name=node_exporter \
	quay.io/prometheus/node-exporter \
	\
	--path.rootfs=/host

touch "$scriptCompleted"
exit 0
