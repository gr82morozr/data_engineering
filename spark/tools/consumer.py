from confluent_kafka import Consumer, KafkaError

# Kafka broker address
bootstrap_servers = 'localhost:9092'

# Create a Kafka consumer configuration
consumer_config = {
    'bootstrap.servers': bootstrap_servers,
    'group.id': 'test-group1',  # Consumer group ID
    'auto.offset.reset': 'earliest'  # Start consuming from the beginning of the topic
}

# Create a Kafka consumer instance
consumer = Consumer(consumer_config)

# Subscribe to the Kafka topic
topic = 'test-topic'
consumer.subscribe([topic])

# Poll for messages and process them
try:
    while True:
        msg = consumer.poll(1.0)

        if msg is None:
            continue
        if msg.error():
            if msg.error().code() == KafkaError._PARTITION_EOF:
                continue
            else:
                print(f"Error: {msg.error()}")
                break

        print(f"Received message: {msg.value()}")

except KeyboardInterrupt:
    pass

finally:
    # Close the Kafka consumer
    consumer.close()
