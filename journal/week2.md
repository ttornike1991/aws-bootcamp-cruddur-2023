# Week 2 — Distributed Tracing

# 1 HoneyComb

When creating a new dataset in Honeycomb it will provide all these installation insturctions

We'll add the following files to our <code> requirements.txt </code>:
  
```
opentelemetry-api 
opentelemetry-sdk 
opentelemetry-exporter-otlp-proto-http 
opentelemetry-instrumentation-flask 
opentelemetry-instrumentation-requests
  
```
We'll install these dependencies:

```
pip install -r requirements.txt
```
Add to the <code> app.py </code>:
 
```
from opentelemetry import trace
from opentelemetry.instrumentation.flask import FlaskInstrumentor
from opentelemetry.instrumentation.requests import RequestsInstrumentor
from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
```
```
# Initialize tracing and an exporter that can send data to Honeycomb
provider = TracerProvider()
processor = BatchSpanProcessor(OTLPSpanExporter())
provider.add_span_processor(processor)
trace.set_tracer_provider(provider)
tracer = trace.get_tracer(__name__)
```
```
# Initialize automatic instrumentation with Flask
app = Flask(__name__)
FlaskInstrumentor().instrument_app(app)
RequestsInstrumentor().instrument()

```
Add the following Env Vars to <code> backend-flask </code> in docker compose:
```
OTEL_EXPORTER_OTLP_ENDPOINT: "https://api.honeycomb.io"
OTEL_EXPORTER_OTLP_HEADERS: "x-honeycomb-team=${HONEYCOMB_API_KEY}"
OTEL_SERVICE_NAME: "${HONEYCOMB_SERVICE_NAME}"
```
You'll need to grab the API key from your honeycomb account:

```
export HONEYCOMB_API_KEY=""
export HONEYCOMB_SERVICE_NAME="Cruddur"
gp env HONEYCOMB_API_KEY=""
gp env HONEYCOMB_SERVICE_NAME="Cruddur"
```
**Add custom instrumentation to Honeycomb to add more attributes eg. UserId, Add a custom span**

![user id](https://user-images.githubusercontent.com/100797221/222235904-53bf78f1-6e72-40ad-a9f7-2467a2d59314.png)

**run queries to explore traces within Honeycomb.io**

**#1**
![query1](https://user-images.githubusercontent.com/100797221/222235966-cf6962de-850f-415d-8131-c020abbfc6fd.png)
**#2**
![query2](https://user-images.githubusercontent.com/100797221/222235994-a02beeb1-e721-4371-847f-b91e982ef3c6.png)
**#3**
![query3](https://user-images.githubusercontent.com/100797221/222236001-e1f7dbc5-9de4-4fec-a800-2b4b10087719.png)



# 2 Rollbar
[https://rollbar.com/](https://rollbar.com/)

Create a new project in Rollbar called <code> Cruddur </code>

Add to <code> requirements.txt </code>:

```
blinker
rollbar
```
Install deps:

```
pip install -r requirements.txt
```
We need to set our access token:
```
export ROLLBAR_ACCESS_TOKEN=""
gp env ROLLBAR_ACCESS_TOKEN=""
```
Add to backend-flask for <code> docker-compose.yml </code>
```
ROLLBAR_ACCESS_TOKEN: "${ROLLBAR_ACCESS_TOKEN}"
```
Import for Rollbar:
```
import rollbar
import rollbar.contrib.flask
from flask import got_request_exception

```

```
rollbar_access_token = os.getenv('ROLLBAR_ACCESS_TOKEN')
@app.before_first_request
def init_rollbar():
    """init rollbar module"""
    rollbar.init(
        # access token
        rollbar_access_token,
        # environment name
        'production',
        # server root directory, makes tracebacks prettier
        root=os.path.dirname(os.path.realpath(__file__)),
        # flask already sets up logging
        allow_logging_basic_config=False)

    # send exceptions from `app` to rollbar, using flask's signal system.
    got_request_exception.connect(rollbar.contrib.flask.report_exception, app)
		
```
We'll add an endpoint just for testing rollbar to <code> app.py</code>:
```
@app.route('/rollbar/test')
def rollbar_test():
    rollbar.report_message('Hello World!', 'warning')
    return "Hello World!"

```

[Rollbar Flask Example](https://github.com/rollbar/rollbar-flask-example/blob/master/hello.py)

 
**Trigger an error an observe an error with Rollbar:**

![rollbar](https://user-images.githubusercontent.com/100797221/222237339-71e9691b-123b-4a1c-84a9-62e4c34a2e58.png)

# 3 X-ray

**Instrument AWS X-Ray for Flask**
```
export AWS_REGION=
gp env AWS_REGION=
```

Add to the <code>  requirements.txt </code>
```
aws-xray-sdk

```

Install pythondependencies:
```
pip install -r  requirements.txt
```

Add to <code> app.py </code>
```
from aws_xray_sdk.core import xray_recorder
from aws_xray_sdk.ext.flask.middleware import XRayMiddleware

xray_url = os.getenv("AWS_XRAY_URL")
xray_recorder.configure(service='Cruddur', dynamic_naming=xray_url)
XRayMiddleware(app, xray_recorder)
```

![x-ray-traces](https://user-images.githubusercontent.com/100797221/222680759-a05cdd47-933d-446d-8e54-bd65080070a4.png)

**Setup AWS X-Ray Resources**
Add <code> aws/json/xray.json </code>
```
{
  "SamplingRule": {
      "RuleName": "Cruddur",
      "ResourceARN": "*",
      "Priority": 9000,
      "FixedRate": 0.1,
      "ReservoirSize": 5,
      "ServiceName": "backend-flask",
      "ServiceType": "*",
      "Host": "*",
      "HTTPMethod": "*",
      "URLPath": "*",
      "Version": 1
  }
}
```

```

FLASK_ADDRESS="https://4567-${GITPOD_WORKSPACE_ID}.${GITPOD_WORKSPACE_CLUSTER_HOST}"
aws xray create-group \
   --group-name "Cruddur" \
   --filter-expression "service(\"backend-flask\") "
```
```
aws xray create-sampling-rule --cli-input-json file://aws/json/xray.json
```
![x-raygroop](https://user-images.githubusercontent.com/100797221/222681111-fc7919cd-458b-42e9-9ef7-f70e9d7b890d.png)
![samplingxray](https://user-images.githubusercontent.com/100797221/222681124-e2dd68fe-0649-49f5-b006-f56b6d4f5982.png)


**Add Deamon Service to Docker Compose**
```
  xray-daemon:
    image: "amazon/aws-xray-daemon"
    environment:
      AWS_ACCESS_KEY_ID: "${AWS_ACCESS_KEY_ID}"
      AWS_SECRET_ACCESS_KEY: "${AWS_SECRET_ACCESS_KEY}"
      AWS_REGION: "us-east-1"
    command:
      - "xray -o -b xray-daemon:2000"
    ports:
      - 2000:2000/udp
```
We need to add these two env vars to our backend-flask in our <code > docker-compose.yml </code> file:
```
      AWS_XRAY_URL: "*4567-${GITPOD_WORKSPACE_ID}.${GITPOD_WORKSPACE_CLUSTER_HOST}*"
      AWS_XRAY_DAEMON_ADDRESS: "xray-daemon:2000"
      
 ```
 
 
 

 
 
 **setup custom subsegment trace loging***
 ![custom-segment](https://user-images.githubusercontent.com/100797221/222680584-9a4ef0ea-f455-4d8f-b0d0-553a310f2dfb.png)
     
![activities_home](https://user-images.githubusercontent.com/100797221/222681170-157009ef-5180-46dd-979d-99ee90b0afb1.png)

# 4 CloudWatch Logs

Add to the <code>requirements.txt:</code>
```
watchtower
```
Install pythondependencies:
```
pip install -r  requirements.txt
```

In <code>app.py</code>
In app.py
```
import watchtower
import logging
from time import strftime
```
```
# Configuring Logger to Use CloudWatch
LOGGER = logging.getLogger(__name__)
LOGGER.setLevel(logging.DEBUG)
console_handler = logging.StreamHandler()
cw_handler = watchtower.CloudWatchLogHandler(log_group='cruddur')
LOGGER.addHandler(console_handler)
LOGGER.addHandler(cw_handler)
LOGGER.info("some message")
```
```
@app.after_request
def after_request(response):
    timestamp = strftime('[%Y-%b-%d %H:%M]')
    LOGGER.error('%s %s %s %s %s %s', timestamp, request.remote_addr, request.method, request.scheme, request.full_path, response.status)
    return response
```
Set the env var in your <code>backend-flask</code> for <code>docker-compose.yml</code>
```
      AWS_DEFAULT_REGION: "${AWS_DEFAULT_REGION}"
      AWS_ACCESS_KEY_ID: "${AWS_ACCESS_KEY_ID}"
      AWS_SECRET_ACCESS_KEY: "${AWS_SECRET_ACCESS_KEY}"
```

![cloudwatch](https://user-images.githubusercontent.com/100797221/222728448-e7f1bed2-2963-4757-b6e2-300fb2340968.png)


