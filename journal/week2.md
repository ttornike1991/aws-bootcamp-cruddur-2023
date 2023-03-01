# Week 2 — Distributed Tracing

# 1 HoneyComb

When creating a new dataset in Honeycomb it will provide all these installation insturctions

We'll add the following files to our <code> requirements.txt <code>.
  
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
Add to the <code> app.py <code>
  
  ```
from opentelemetry import trace
from opentelemetry.instrumentation.flask import FlaskInstrumentor
from opentelemetry.instrumentation.requests import RequestsInstrumentor
from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
  ```
