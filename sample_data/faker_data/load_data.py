from faker import Faker
import random
from datetime import datetime

fake = Faker()

def generate_products(number_of_records):
    products = []
    product_types = [
        ("Laptop", "This {} laptop comes with {} GB RAM, {} GB SSD, and a powerful {} processor."),
        ("Chair", "This comfortable {} chair is made of {} and designed for long working hours."),
        ("Phone", "This {} phone features a {} inch screen, {} camera, and {} battery life."),
    ]

    for _ in range(number_of_records):
        prod_id = random.randint(1000, 9999)
        product_type, description_template = random.choice(product_types)
        short_name = product_type
        long_description = description_template.format(
            fake.word(),
            fake.random_int(min=8, max=64),
            fake.random_int(min=128, max=1024),
            fake.word()
        )
        unit_price = round(random.uniform(10.5, 99.9), 2)

        products.append({
            "prod_id": prod_id,
            "short_name": short_name,
            "long_description": long_description,
            "unit_price": unit_price
        })

    return products

def generate_sales(number_of_records):
    sales = []
    for _ in range(number_of_records):
        customer_id = random.randint(100000, 999999)
        quantities = random.randint(1, 100)
        name = fake.name()
        address = fake.address().replace('\n', ', ')
        IP = fake.ipv4_public()
        timestamp = datetime.now().isoformat()

        sales.append({
            "customer_id": customer_id,
            "quantities": quantities,
            "name": name,
            "address": address,
            "IP": IP,
            "timestamp": timestamp
        })

    return sales

products = generate_products(10)
sales = generate_sales(10)

for product in products:
    print(product)

for sale in sales:
    print(sale)
