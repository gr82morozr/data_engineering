ES_HOST="https://localhost:9200"
AUTH=" elastic:password "
HEADER="Content-Type: application/json"


curl -k -u $AUTH -X PUT "${ES_HOST}/_index_template/mylog_template" -H "${HEADER}" -d'
{
  "index_patterns": ["mylog-*"],  // Apply this template to any index named like log-*
  "template": {
    "settings": {
      "number_of_shards": 2,
      "number_of_replicas": 1
    },
    "mappings": {
      "properties": {
        "timestamp": {
          "type": "date"
        },
        "message": {
          "type": "text"
        },
        "level": {
          "type": "keyword"
        }
      }
    },
    "aliases": {
      "all_logs": {}
    }
  },
  "priority": 1
}
' | jq .


PUT _component_template/component_template1
{
  "template": {
    "mappings": {
      "properties": {
        "@timestamp": {
          "type": "date"
        }
      }
    }
  }
}
