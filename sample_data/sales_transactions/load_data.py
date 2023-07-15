import os
import sys
import re
import json
import requests
import urllib3
import pandas
from zipfile import ZipFile



# Suppress the specific warning
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

HEADERS = { 'Content-Type': 'application/json'  }

def get_config() :
  config = {
    "DATA_FILE"   : "./sales_transaction.zip", 
    "ES_HOST"     : "https://localhost:9200",
    "ES_USERNAME" : "elastic",
    "ES_PASSWORD" : "password",
    "ES_INDEX"    : "sales_transaction"
  }
  return config


def extract_zip(input_zip):
  input_zip=ZipFile(input_zip)
  data = {name: input_zip.read(name).decode("utf-8").replace('\n', ' ').replace("\"", "'") for name in input_zip.namelist()}
  return data

def parse_data(data):
  pattern = r"/([^/]+)/"
  es_data = []
  # Extract the middle part from the match
  for k in data.keys():
    # Apply the regex pattern to the string
    match = re.search(pattern, k)
    if match is None : continue
    key = match.group(1)
    es_data.append({"category": key, "news" : data[k] })
  
  return es_data

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
            "number_of_shards": 6,
            "number_of_replicas": 1
        },
        "mappings": {
          "properties": {
            "category": {
              "type": "text",
              "fields": {
                "keyword": {
                  "type": "keyword",
                  "ignore_above": 256
                }
              }
            },
            "news": {
              "type": "text",
              "fields": {
                "keyword": {
                  "type": "keyword",
                  "ignore_above": 256
                }
              }
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
        print(f'Index "{index_name}" created successfully.')
    else:
        print(f'Failed to create index "{index_name}". Status code: {response.status_code}')

def load_es(es_data):
  config = get_config()
  
  delete_es_index( config['ES_INDEX'], config['ES_HOST'], config['ES_USERNAME'], config['ES_PASSWORD'] )
  create_es_index( config['ES_INDEX'], config['ES_HOST'], config['ES_USERNAME'], config['ES_PASSWORD'] )

  for doc in es_data:
    print (doc["category"])
    # Make the HTTP POST request to Elasticsearch
    response = requests.post(
      config['ES_HOST'] + '/' + config['ES_INDEX'] + '/_doc',
      headers=HEADERS,
      auth=(config['ES_USERNAME'], config['ES_PASSWORD']),
      data=json.dumps(doc),
      verify=False
    )

    # Check the response status
    if response.status_code == 201:
      #print('Data pushed to Elasticsearch successfully.')
      pass
    else:
      print(f'Failed to push data to Elasticsearch. Status code: {response.status_code}')
  print ("all done.")


def main() : 
  config = get_config()
  data = extract_zip(config["DATA_FILE"])
  data = parse_data(data)
  load_es(data)
  pass


if __name__ == "__main__":
  main()