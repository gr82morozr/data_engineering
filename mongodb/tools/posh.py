from pymongo import MongoClient
import random

# MongoDB connection details
host = 'localhost'
port = 27017
username = 'root'
password = 'example'
database_name = 'gmail_archive'

# Create the connection string
connection_string = f"mongodb://{username}:{password}@{host}:{port}/"

# Connect to MongoDB
client = MongoClient(connection_string)

# Select the database
db = client[database_name]

# Select the collection
collection = db['messages']

# Sample data to insert
data = [
    {"name": "Alice", "age": 30, "city": "New York"},
    {"name": "Bob", "age": 25, "city": "Paris"},
    {"name": "Charlie", "age": 35, "city": "London"}
]

# Inserting the data into the collection
collection.insert_many(data)

print("Data inserted successfully.")
