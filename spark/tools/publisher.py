from confluent_kafka import Producer

# Kafka broker address
bootstrap_servers = 'kafka:9092'

# Create a Kafka producer configuration
producer_config = {
    'bootstrap.servers': bootstrap_servers,
}

# Create a Kafka producer instance
producer = Producer(producer_config)

# Kafka topic to publish messages to
topic = 'test-topic'

# Define a callback function to handle delivery reports
def delivery_report(err, msg):
    if err is not None:
        print(f'Message delivery failed: {err}')
    else:
        print(f'Message delivered to {msg.topic()} [{msg.partition()}]')

# Publish a message to the Kafka topic
message_key = 'key1'
message_value = 'Hello, Kafka!'
producer.produce(topic, key=message_key, value=message_value, callback=delivery_report)

# Wait for any outstanding messages to be delivered and delivery reports to be received
producer.flush()