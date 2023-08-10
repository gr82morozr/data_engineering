import os
import sys
import re
import json
import requests
import urllib3
import pandas as pd
from zipfile import ZipFile



# Suppress the specific warning
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

HEADERS = { 'Content-Type': 'application/json'  }

def get_config() :
  config_credits = {
    "DATA_FILE"   : "./tmdb_5000_credits.csv", 
    "ES_HOST"     : "https://localhost:9200",
    "ES_USERNAME" : "elastic",
    "ES_PASSWORD" : "password",
    "ES_INDEX"    : "tmdb_credits"
  }

  config_movies = {
    "DATA_FILE"   : "./tmdb_5000_movies.csv", 
    "ES_HOST"     : "https://localhost:9200",
    "ES_USERNAME" : "elastic",
    "ES_PASSWORD" : "password",
    "ES_INDEX"    : "tmdb_movies"
  }
 
  return config_movies, config_credits


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
            "Country": {
              "type": "text",
              "fields": {
                "keyword": {
                  "type": "keyword",
                  "ignore_above": 256
                }
              }
            },
            "CustomerNo": {
              "type": "text",
              "fields": {
                "keyword": {
                  "type": "keyword",
                  "ignore_above": 256
                }
              }
            },
            "Date": {
              "type": "date",
              "format": "MM/d/yyyy||MM/dd/yyyy||M/dd/yyyy||M/d/yyyy"
            },
            "Price": {
              "type": "float"
            },
            "ProductName": {
              "type": "text",
              "fields": {
                "keyword": {
                  "type": "keyword",
                  "ignore_above": 256
                }
              }
            },
            "ProductNo": {
              "type": "text",
              "fields": {
                "keyword": {
                  "type": "keyword",
                  "ignore_above": 256
                }
              }
            },
            "Quantity": {
              "type": "long"
            },
            "TransactionNo": {
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

  
  payload = ''
  bulk_count = 0
  for doc in es_data:
    # Make the HTTP POST request to Elasticsearch
    bulk_count +=1
    payload += '{ "index": { "_index": "' + config['ES_INDEX'] + '" , "_id" : "' +  str(bulk_count) + '"} }' + "\n"
    payload += json.dumps(doc) + "\n"

    if bulk_count % 4000 ==0 : 
      response = requests.post(
        config['ES_HOST'] + '/_bulk',
        headers=HEADERS,
        auth=(config['ES_USERNAME'], config['ES_PASSWORD']),
        data=payload,
        verify=False
      )
      print (str(bulk_count) + " => " + str(response.status_code))
      payload = ''
      
  
  response = requests.post(
    config['ES_HOST'] + '/_bulk',
    headers=HEADERS,
    auth=(config['ES_USERNAME'], config['ES_PASSWORD']),
    data=payload,
    verify=False
  )
  print (str(bulk_count) + " => " + str(response.status_code))



  response = requests.post( 
    config['ES_HOST'] + '/' + config['ES_INDEX'] + '/_refresh',
    headers=HEADERS,
    auth=(config['ES_USERNAME'], config['ES_PASSWORD']),
    verify=False)
  

  print ("all done.")

def verify_es(es_data) :

  config = get_config()
  missing_count =0

  pay_load = {
     "docs" : [
        
     ]
  }

  for i in range(1,len(es_data)+1):
    data = {  "_id": str(i) }
    pay_load["docs"].append ( data)

    if i % 1000 ==0 : 
      response = requests.get( 
        config['ES_HOST'] + '/' + config['ES_INDEX'] + '/_mget/' ,
        headers=HEADERS,
        auth=(config['ES_USERNAME'], config['ES_PASSWORD']),
        data= json.dumps(pay_load),
        verify=False)
      
      response_dic = json.loads(response.text)
      missing_ids = [ doc["_id"] for doc in response_dic["docs"] if not doc["found"] ]
      print (str(i) + ":" + str(len(missing_ids)));


def main() : 
  config = get_config()
  df = pd.read_csv('./tmdb_5000_movies.csv')  
  data_dict = df.to_dict(orient='records')
  load_es(data_dict)

  pass


if __name__ == "__main__":
  main()