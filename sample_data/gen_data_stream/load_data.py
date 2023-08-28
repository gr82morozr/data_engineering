from operator import index
import os
import sys
import re
import json
import requests
import urllib3
import py3toolbox as tb
import time



# Suppress the specific warning
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

HEADERS = { 'Content-Type': 'application/json'  }
INDEX_CREATED_TIME = time.time()

def get_config() :
  config = {
    "ES_HOST"     : "https://nas1:9200",
    "ES_USERNAME" : "elastic",
    "ES_PASSWORD" : "password",
    "ES_INDEX"    : "log-events"
  }
  return config



def delete_es_index(index_name, es_url, es_username, es_password):
  # Make the HTTP DELETE request to Elasticsearch
  response = requests.delete(
    f'{es_url}/{index_name}',
    auth=(es_username, es_password),
    verify=False
  )

  # Check the response status
  if response.status_code == 200:
    print(f'Index "{index_name}" deleted successfully.')
  else:
    print(f'Failed to delete index "{index_name}". Status code: {response.status_code}')

def create_es_index(index_name, es_url, es_username, es_password):
    # Create the request URL
    url = f'{es_url}/{index_name}'
    
    # Elasticsearch settings
    settings = {
        "settings": {
            "number_of_shards": 1,
            "number_of_replicas": 1
        },
        "mappings": {
          "properties": {
            "message": {
              "type": "text"
            },
            "@timestamp": {
              "type" : "date",
              "format": "yyyy-MM-dd HH:mm:ss"
            }
          }
        }
    }

    # Create the index with settings and mappings
    response = requests.put(
        url,
        auth=(es_username, es_password),
        headers=HEADERS,
        data=json.dumps(settings),
        verify=False
    )
    # Check the response status
    if response.status_code == 200:
      INDEX_CREATED_TIME = time.time()
      print(f'Index "{index_name}" created successfully.')
    else:
        print(f'Failed to create index "{index_name}". Status code: {response.status_code}')


def load_es():
  config = get_config()
  
  #delete_es_index( config['ES_INDEX'], config['ES_HOST'], config['ES_USERNAME'], config['ES_PASSWORD'] )
  create_es_index( config['ES_INDEX'], config['ES_HOST'], config['ES_USERNAME'], config['ES_PASSWORD'] )

  es_url = config["ES_HOST"]
  index_name = config['ES_INDEX']
  es_username = config["ES_USERNAME"]
  es_password = config["ES_PASSWORD"]

  url = f'{es_url}/{index_name}/_doc'
  count = 0
  while True:
    count +=1
    time_elipsed = str(time.time() - INDEX_CREATED_TIME)
    request = {
      "@timestamp" : tb.get_timestamp() ,
      "message"    : str(count) + " : " + time_elipsed + "s -  message @ " + tb.get_timestamp()
    }

    response = requests.post(
        url,
        auth=(es_username, es_password),
        headers=HEADERS,
        data=json.dumps(request),
        verify=False
    )
    print(json.dumps(request))
    print(response.status_code)
    time.sleep(1);
 
  print ("all done.")


def main() : 
  config = get_config()
  load_es()
  pass


if __name__ == "__main__":
  main()
