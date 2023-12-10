# Use the official MongoDB image as the base image
FROM mongo:latest

# Install Node.js and npm
RUN apt-get update && apt-get install -y curl gnupg
RUN curl -fsSL https://deb.nodesource.com/setup_16.x | bash -
RUN apt-get install -y nodejs

# Clean npm cache
RUN npm cache clean --force

# Install Mongo Express
# Clone and build Mongo Express (Example, modify as needed)
RUN git clone https://github.com/mongo-express/mongo-express.git
WORKDIR /mongo-express
RUN npm install

# Set environment variables for MongoDB
ENV MONGO_INITDB_ROOT_USERNAME root
ENV MONGO_INITDB_ROOT_PASSWORD example

# Set environment variables for Mongo Express
ENV ME_CONFIG_MONGODB_ADMINUSERNAME root
ENV ME_CONFIG_MONGODB_ADMINPASSWORD example
ENV ME_CONFIG_MONGODB_SERVER localhost

# Copy a script that starts MongoDB and Mongo Express
COPY start_services.sh /usr/local/bin/

# Set the script as the entrypoint
ENTRYPOINT ["start_services.sh"]
