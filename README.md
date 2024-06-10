# DigitalOcean-DDNS

This service allows you to dynamically update your DNS records on DigitalOcean using a custom dynamic DNS service. It is implemented using OpenResty (Nginx with Lua support) and can handle both IPv4 and IPv6 addresses. This can be particularly useful for updating DNS records when your IP address changes frequently, such as in residential setups.

## Features

- Supports both IPv4 and IPv6 updates.
- Authenticates requests using basic HTTP authentication.

## Prerequisites

- Docker
- Docker Compose (optional, for running with Docker Compose)
- DigitalOcean API key

## Getting Started

### Environment Variables

The service uses the following environment variables, which need to be set:

- `DO_AUTH_TOKEN`: Your DigitalOcean API token.
- `DO_DOMAIN_NAME`: The domain name managed in DigitalOcean.
- `DO_SUBDOMAIN`: The subdomain to update.
- `DDNS_PASSWORD`: The password for HTTP basic authentication.

### Building the Docker Image

To build the Docker image, run:

   ```bash
   docker build -t digitalocean-ddns .
   ```

### Running the Docker container

To run the Docker container, use:

```bash
docker run -d -p 8080:8080 \
  --name digitalocean-ddns \
  -e DO_AUTH_TOKEN=your_digital_ocean_api_key \
  -e DO_DOMAIN_NAME=your_domain_name \
  -e DO_SUBDOMAIN=your_subdomain \
  -e DDNS_PASSWORD=your_ddns_password \
  samuelme/digitalocean-ddns
```

Replace `your_digital_ocean_api_key`, `your_domain_name`, and `your_subdomain` with your actual values.


## Configuration with AVM's Fritz!Box DynDNS Mechanism

To configure this service with **AVM's Fritz!Box DynDNS** mechanism, follow these steps:

1. Open the Fritz!Box web interface.
1. Go to `Internet` > `Permit Access` > `DynDNS`.
1. Enable `Use DynDNS` function.
1. Enter the `Update URL` in the format:

```
http://ddns_user:<pass>@localhost:8080/nic/update?hostname=<domain>&myip=<ipaddr>&myipv6=<ip6addr>
```
1. Enter your `Domain name`: (e.g. `home.example.com`)
1. Enter your `Username` (_optional_ won't be used)
1. Enter your `Password` (`DDNS_PASSWORD`)


## Docker Compose

You can also use Docker Compose to run the service. Create a `docker-compose.yml` file with the following content:

```yaml
services:
  digitalocean-ddns:
    image: samuelme/digitalocean-ddns
    container_name: digitalocean-ddns
    ports:
      - "8080:8080"
    environment:
      - DO_AUTH_TOKEN=${DO_AUTH_TOKEN}
      - DO_DOMAIN_NAME=example.com
      - DO_SUBDOMAIN=home
      - DDNS_PASSWORD=${DDNS_PASSWORD}
```

It is recommendet to store sensitive information in an `.env` file:

```ini
DO_AUTH_TOKEN=your_digital_ocean_auth_token
DDNS_PASSWORD=your_ddns_password
```

Run the service with Docker Compose:

```bash
docker-compose up -d
```

## Environment Variables

- `DO_AUTH_TOKEN`: Your DigitalOcean API key. This is required to authenticate API requests to DigitalOcean.
- `DO_DOMAIN_NAME`: Your domain name. (e.g. `example.com`)
- `DO_SUBDOMAIN`: Your subdomain. (e.g. `home`)
- `DDNS_PASSWORD`: This is required to authenticate against the `/nic/update` service endpoint.

## License

This project is licensed under the MIT License.
