## Grafana
See `run.sh`.

### GCP
Partition containig this repo may not be executable, hence run it with:
```
$ sudo sh ./run.sh
```

Auto startup: add the metadata key `startup-script` with this content:
```
#!/bin/sh
/bin/sh /home/USERNAME/monitoring/run.sh
```
### Backup volumes
```
sudo docker run --rm --volumes-from grafana -v $(pwd):/backup busybox tar cvf /backup/grafana-storage.tar /var/lib/grafana
sudo docker run --rm --volumes-from prom -v $(pwd):/backup busybox tar cvf /backup/prometheus.tar /prometheus
```

## InfluxDB
Just a quick test:
```
$ docker run --rm -it \
	--name influxdb \
	-p 8086:8086 -p 8888:8888 \
	influxdb

# New telegraf config
$ docker run --rm telegraf telegraf config > telegraf.conf

$ docker run --rm -it --name=telegraf --net=container:influxdb \
	-v $PWD/telegraf.conf:/etc/telegraf/telegraf.conf:ro \
	-v /:/hostfs:ro \
	-e HOST_ETC=/hostfs/etc \
	-e HOST_PROC=/hostfs/proc \
	-e HOST_SYS=/hostfs/sys \
	-e HOST_VAR=/hostfs/var \
	-e HOST_RUN=/hostfs/run \
	-e HOST_MOUNT_PREFIX=/hostfs \
	telegraf

$ docker run -it --rm \
	--net=container:influxdb \
	chronograf --influxdb-url=http://127.0.0.1:8086
```
