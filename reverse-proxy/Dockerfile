# Use the official Apache HTTP Server image from the Docker Hub
FROM httpd:2.4

# Copy your custom configuration file into the container
COPY ./httpd.conf /usr/local/apache2/conf/httpd.conf

# Copy SSL certificates
COPY ./certs/ /usr/local/apache2/certs/
