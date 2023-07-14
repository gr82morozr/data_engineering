source ../.env

# clean up folders
rm -fr ./temp
mkdir temp
unzip ../../../sample_data/nasa_apache_access/nasa_apache_access.zip -d ./temp

filebeat_image=filebeat:${ELK_VERSION}

docker rm -f filebeat
docker build --build-arg ELK_VERSION=${ELK_VERSION} -t $filebeat_image  .

docker run --name filebeat --network=elk8_elk_network -v ./temp:/usr/share/filebeat/input_data -d ${filebeat_image} 

#docker cp $(docker create ${filebeat_image}):/usr/share/filebeat/filebeat.reference.yml .

filebeat_exec="docker exec filebeat /usr/share/filebeat/filebeat "


echo Checking config ...
output=$($filebeat_exec test config)
if ! echo "$output" | grep -q "Config OK"; then
  echo $output
  echo "Config Error, check filebeat.yml"
  exit 1
fi

echo Checking output ...
output=$($filebeat_exec test output)
if ! echo "$output" | grep -q "talk to server... OK"; then
  echo $output
  echo "Output Error, check filebeat.yml"
  exit 1
fi

echo Setup ...
output=$($filebeat_exec setup)
echo $output


echo Run ...
docker exec -d filebeat /usr/share/filebeat/filebeat -e


docker logs -f filebeat
