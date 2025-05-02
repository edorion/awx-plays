#!/bin/bash

# This script Gets Datadog metrics and filters to root disks then manages the root disk monitor

api_key="**********************"
app_key="**************************"

from_time=$(($(date +%s)-86400)) #last 2 days
to_time=$(date +%s)
from_time=$(date --date='1 day ago' +%s)
query="avg(last_5m):"

# --- uncomment to list available metrics from the listed host
#curl -X GET \
#-H "DD-API-KEY: ${api_key}" \
#-H "DD-APPLICATION-KEY: ${app_key}" \
#"https://api.datadoghq.com/api/v1/metrics?from=${from_time}&host=sk.live.schoolbox" | jq
#j=0

count=0
#getting all on prem hosts
hostlist=$(jq -r '.host_list[] | select( .host_name | contains(".live.app")) .host_name' <<< $(curl -X GET -H "DD-API-KEY: ${api_key}" -H "DD-APPLICATION-KEY: ${app_key}" "https://api.datadoghq.com/api/v1/hosts?count=1000"))

for i in ${hostlist}
do
    #checking for root LVM's
    for j in $(jq -r '.series[] | select(.expression | contains("root") or contains("ubuntu--vg-ubuntu--lv") or contains("/dev/nvme1n1p1,") or contains("/dev/xvda1") or contains("/dev/nvme2n1p1") or contains("device:/dev/sda2,") or contains("device:/dev/sda2}")) | .expression' <<< $(curl -s -X GET -H "DD-API-KEY: ${api_key}" -H "DD-APPLICATION-KEY: ${app_key}" "https://api.datadoghq.com/api/v1/query?&query=avg:system.disk.free\{${i}\}by\{device\}&from=${from_time}&to=${to_time}"))
    do
      echo -e "\n$i - $j"
      if [ $j != "" ]
        then
          # First delete the monitors
          for k in $(jq -r --arg jquery "$j" '.[] | select(.query | contains($jquery)) | .id' <<< $(curl -s -X GET -H "DD-API-KEY: ${api_key}" -H "DD-APPLICATION-KEY: ${app_key}" "https://api.datadoghq.com/api/v1/monitor"))
          do
            echo -e "\ndeleting $k"
            curl -X DELETE "https://api.datadoghq.com/api/v1/monitor/${k}?force=true&api_key=${api_key}&application_key=${app_key}"
          done

          # then create the monitor
          query=$query$j" by {host} < 3000000000"
          echo -e "\nCreating monitor: host - $i query - $query"
          sed 's/xxxxxxxxxx/'"${query//\//\\/}"'/g' LowDisk.json > LowDiskTmp.json
          sed -i 's/yyyyyyyyyy/'"$i"'/g' LowDiskTmp.json
          curl -X POST -H "Content-type: application/json" -H "DD-API-KEY: ${api_key}" -H "DD-APPLICATION-KEY: ${app_key}" -d @LowDiskTmp.json "https://api.datadoghq.com/api/v1/monitor"
          query="avg(last_5m):"
          continue 2
      fi
    done

    #checking for sda2
    for j in $(jq -r '.series[] | select(.expression | contains("device:/dev/sda2,") or contains("device:/dev/sda2}")) | .expression' <<< $(curl -s -X GET -H "DD-API-KEY: ${api_key}" -H "DD-APPLICATION-KEY: ${app_key}" "https://api.datadoghq.com/api/v1/query?&query=avg:system.disk.free\{${i}\}by\{device\}&from=${from_time}&to=${to_time}"))
    do
      echo -e "\n$i - $j"
      if [ $j != "" ]
        then
          # First delete the monitors
          for k in $(jq -r --arg jquery "$j" '.[] | select(.query | contains($jquery)) | .id' <<< $(curl -s -X GET -H "DD-API-KEY: ${api_key}" -H "DD-APPLICATION-KEY: ${app_key}" "https://api.datadoghq.com/api/v1/monitor"))
          do
            echo -e "\ndeleting $k"
            curl -X DELETE "https://api.datadoghq.com/api/v1/monitor/${k}?force=true&api_key=${api_key}&application_key=${app_key}"
          done

          # then create the monitor
          query=$query$j" by {host} < 3000000000"
          echo -e "\nCreating monitor: host - $i query - $query"
          sed 's/xxxxxxxxxx/'"${query//\//\\/}"'/g' LowDisk.json > LowDiskTmp.json
          sed -i 's/yyyyyyyyyy/'"$i"'/g' LowDiskTmp.json
          curl -X POST -H "Content-type: application/json" -H "DD-API-KEY: ${api_key}" -H "DD-APPLICATION-KEY: ${app_key}" -d @LowDiskTmp.json "https://api.datadoghq.com/api/v1/monitor"
          query="avg(last_5m):"
          continue 2
      fi
    done

    #checking for sda1's
    for j in $(jq -r '.series[] | select(.expression | contains("device:/dev/sda1,") or contains("device:/dev/sda1}")) | .expression' <<< $(curl -s -X GET -H "DD-API-KEY: ${api_key}" -H "DD-APPLICATION-KEY: ${app_key}" "https://api.datadoghq.com/api/v1/query?&query=avg:system.disk.free\{${i}\}by\{device\}&from=${from_time}&to=${to_time}"))
    do
      echo -e "\n$i - $j"
      # First delete the monitors
      for k in $(jq -r --arg jquery "$j" '.[] | select(.query | contains($jquery)) | .id' <<< $(curl -s -X GET -H "DD-API-KEY: ${api_key}" -H "DD-APPLICATION-KEY: ${app_key}" "https://api.datadoghq.com/api/v1/monitor"))
      do
        echo -e "\ndeleting $k"
        curl -X DELETE "https://api.datadoghq.com/api/v1/monitor/${k}?force=true&api_key=${api_key}&application_key=${app_key}"
      done

      # then create the monitor
      query=$query$j" by {host} < 3000000000"
      echo -e "\nCreating monitor: host - $i query - $query"
      sed 's/xxxxxxxxxx/'"${query//\//\\/}"'/g' LowDisk.json > LowDiskTmp.json
      sed -i 's/yyyyyyyyyy/'"$i"'/g' LowDiskTmp.json
      curl -X POST -H "Content-type: application/json" -H "DD-API-KEY: ${api_key}" -H "DD-APPLICATION-KEY: ${app_key}" -d @LowDiskTmp.json "https://api.datadoghq.com/api/v1/monitor"
      query="avg(last_5m):"
    done
done
