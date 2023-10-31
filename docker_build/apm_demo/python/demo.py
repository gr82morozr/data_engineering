from flask import Flask  
from elasticapm.contrib.flask import ElasticAPM

app = Flask(__name__)



app.config['ELASTIC_APM'] = {
          'SERVICE_NAME': 'FlaskApp',
          'SECRET_TOKEN': 'abcdedfgtyyy',         
          'SERVER_URL': 'http://apm-svr:8200',
          'VERIFY_SERVER_CERT' : False,
          'ENVIRONMENT': 'my-environment',
          'DEBUG': True,
          'LOGLEVEL' : 'debug'
}

apm = ElasticAPM(app)

@app.route('/')  
def index():   
  return "Hello World!"  


if __name__ == '__main__':   
  app.run(host='0.0.0.0', port=5000)

