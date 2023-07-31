#curl elastic:password -X GET http://localhost:9200/_index_template

$ES_HOST="https://localhost:9200"
$AUTH=" elastic:password "

#curl -u elastic:password -X GET https://localhost:9200/_index_template -k   | jq .  


curl -k -u elastic:password -X PUT "https://localhost:9200/mydata/_doc/1?pretty" -H 'Content-Type: application/json' -d'
{
  "username": "marywhite",
  "email": "mary@white.com",
  "name": {
    "first": "Mary",
    "middle": "Alice",
    "last": "White"
  }
}
'

curl -k -u elastic:password -X GET "https://localhost:9200/mydata/_settings" | jq .

curl -k -u elastic:password -X GET "https://localhost:9200/mydata/_mappings" | jq .


curl -k -u elastic:password -X PUT "https://localhost:9200/mydata/_doc/1?pretty" -H 'Content-Type: application/json' -d'
{ "count": "aaa"}
'