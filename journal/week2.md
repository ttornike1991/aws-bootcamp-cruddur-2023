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






