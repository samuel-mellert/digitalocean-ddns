FROM openresty/openresty:alpine

# Install required packages
RUN apk update && apk add bash curl jq perl ca-certificates \
    && opm get ledgetech/lua-resty-http

# Copy Nginx configuration
COPY nginx.conf /usr/local/openresty/nginx/conf/nginx.conf

# Copy Lua script
COPY ddns_update.lua /usr/local/openresty/lualib/ddns_update.lua

# Update CA certificates
RUN update-ca-certificates

# Create CA certificates.pem
RUN cp /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.pem

# Expose port
EXPOSE 8080
