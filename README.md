## Synapse Docker Deployment

A Synapse Docker deployment with:

- Hardened Synapse image
- Hardened worker images
- Custom Synapse image that fixes several bugs
  - Default power-level for new rooms is 9001
- Mjolnir & Mjolnir Synapse module
- Multi-threaded Synapse process via workers
- Privacy-respecting registration captcha
- Manage Docker variables inside of `.env`
- Manage `state` with the state compressor
- Manage server via `synadm`
- Images built locally
- Matrix Maubot

### Getting Started

Dependencies: `cargo` `docker` `docker-compose` `git` `python `

Subdomains: `matrix` `element` `maubot`

Clone the repository:
```
git clone https://codeberg.org/deathrow/synapse-docker-deployment
```

CD into the repository:

```
cd synapse-docker-deployment
```

Execute the init script to:

- `git clone` the docker images
- Build the docker images
- Build `auto-state-compressor`
- Install `synadm`

*Will take a long time!*

```
bash init.sh
```

Modify variables inside `.env.sample` and move to `.env`

Run this command to generate the Synapse configuration file:

``
docker-compose run --rm -e SYNAPSE_SERVER_NAME=example.tld -e SYNAPSE_REPORT_STATS=no synapse generate
``

### Synapse Configuration

The Synapse config file will be located at `./files/homeserver.yaml`.

Modify the following:

*You will need to uncomment (#) these*

``web_client_location: https://element.example.tld``

``public_baseurl: https://matrix.example.tld``

``serve_server_wellknown: true``

Under the `listeners:` section, add the following:


```
# For Workers
  - port: 9093
    type: http
    resources:
     - names: [replication]
```
# For Metrics

```
  - type: metrics
    port: 9000
```

Under the `retention:` section, you are able to set retention of messages. 
Uncomment `enabled: false` if you wish to keep messages indefinitely. *(will take up more disk space)*

For the `purge_jobs:` section, add:

```
  purge_jobs:
    - longest_max_lifetime: 1h
      interval: 30m
    - shortest_max_lifetime: 1h
      longest_max_lifetime: 12h
      interval: 1h
    - shortest_max_lifetime: 12h
      longest_max_lifetime: 1d
      interval: 12h
    - shortest_max_lifetime: 1d
      longest_max_lifetime: 10y
      interval: 24h
```

For `caches:` set the following:

```
caches:
  global_factor: 2.0

  per_cache_factors:
    get_users_who_share_room_with_user: 5.0

  sync_response_cache_duration: 2m
```

Under the `databases:` section, remove the default database and add the following:

*(change with the postgres values set inside `.env`)*

Keep the host set to `postgres` as this is the name specified in the `docker-compose.yml`

```
database:
  name: psycopg2
  txn_limit: 10000
  args:
    user: user
    password: password
    database: db
    host: postgres
    port: 5432
    cp_min: 5
    cp_max: 10
```

Under the ``## Ratelimiting ##`` section, add the following:

```
rc_federation:
  window_size: 1000
  sleep_limit: 10
  sleep_delay: 500
  reject_limit: 50
  concurrent: 3

federation_rr_transactions_per_room_per_second: 50
```

Uncomment the `url_preview_enabled: true` and the setting to go with it:

`url_preview_enabled: true`

```
url_preview_ip_range_blacklist:
  - '127.0.0.0/8'
  - '10.0.0.0/8'
  - '172.16.0.0/12'
  - '192.168.0.0/16'
  - '100.64.0.0/10'
  - '192.0.0.0/24'
  - '169.254.0.0/16'
  - '192.88.99.0/24'
  - '198.18.0.0/15'
  - '192.0.2.0/24'
  - '198.51.100.0/24'
  - '203.0.113.0/24'
  - '224.0.0.0/4'
  - '::1/128'
  - 'fe80::/10'
  - 'fc00::/7'
  - '2001:db8::/32'
  - 'ff00::/8'
  - 'fec0::/10'
```

If you wish to use the `url_preview_url_blacklist:` to blacklist certain URLs from being previewed, you can use the following settings:

```
url_preview_url_blacklist:

# blacklist all *.google.com URLs
  - netloc: 'google.com'
  - netloc: '*.google.com'

# blacklist all plain HTTP URLs
  - scheme: 'http'

# blacklist any URL with a literal IPv4 address
  - netloc: '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$'
```

If you wish to change the number of rounds used to generate a password hash, you may modify the ``bcrypt_rounds:`` setting.

Add ``inhibit_user_in_use_error: true``

Add ``suppress_key_server_warning: true``

Add the following:

``send_federation: false``

```
federation_sender_instances:
  - federation1
  - federation2
  - federation3
```

For redis, add the following:

```
redis:
  enabled: true
  host: redis
  port: 6379
```

### Nginx

The path for NGINX is `/swag/nginx`.

Ensure to review each file before you use it, some variables may need changed such as the `matrix.example.tld` and such.

### Start the server

To start the server, type:

`docker-compose up -d`, you may wish to omit the `-d` on the first run to ensure there are no errors.

### Pantalaimon

Modify the `pantalaimon_data/pantalaimon.conf` to change the `matrix.example.tld`

### Mjolnir

Create a new user on your server with the username `mjonlir`.

[Mjolnir Configuration](https://github.com/matrix-org/mjolnir/blob/main/config/default.yaml)

Inside of `mjolnir/config/production.yaml` modify:

Set `homeserverUrl: "http://pantalaimon:8008"`,

Under `pantalaimon:` set `use: true` with the username `mjolnir` and `password:`

Create a new encrypted room on your server and copy the ID and set it as ``managementRoom: !123:example.tld``

Under `web:` set `enabled: true`

Set `displayReports: true`

In `homeserver.yaml` add the following `modules:`

```
modules:
  - module: mjolnir.Module
    config:
      # Prevent servers/users in the ban lists from inviting users on this
      # server to rooms. Default true.
      block_invites: true
      # Flag messages sent by servers/users in the ban lists as spam. Currently
      # this means that spammy messages will appear as empty to users. Default
      # false.
      block_messages: true
      # Remove users from the user directory search by filtering matrix IDs and
      # display names by the entries in the user ban list. Default false.
      block_usernames: true
      # The room IDs of the ban lists to honour. Unlike other parts of Mjolnir,
      # this list cannot be room aliases or permalinks. This server is expected
      # to already be joined to the room - Mjolnir will not automatically join
      # these rooms.
      ban_lists:
         - "!123:example.tld"
         - "!456:example.tld"
      message_max_length:
         # Limit the characters in a message (event body) that a client can send in an event on this server.
         # By default there is no limit (beyond the the limit the spec enforces on event size).
         # Uncomment if you want messages to be limited to 510 characters.
         #threshold: 510

         # Limit messages only in certain rooms rooms.
         # By default all rooms will enforce the limit.
         # Uncomment if you want messages to only be subject to character limits in certain rooms.
         rooms:
           - "!123:localhost:9999"
           - "!456:localhost:9999"

         # Also hide messages from remote servers that are over the `message_limit`.
         # By default only events from this server will be limited.
         # WARNING: Remote users on other servers will still be able to messages over the limit.
         # Uncomment to enforce the `message_limit` on events from remote servers.
         remote_servers: false
```
### Captcha

The [synapse-captcha](https://codeberg.org/deathrow/synapse-captcha) is included with this deployment. Refer to this for configuration.

### Additional

To bypass ratelimits for certain users:

``
docker exec -it postgres psql insert into ratelimit_override values ('@user:example.tld', 0, 0);
``

Your `mjolnir` and any other admin accounts should be set in the example above.

For synapse state compressor:
``
./synapse_auto_compressor -p postgresql://user:password@localhost/db -c 500 -n 100
``
### Todo

- stream workers

- Proper `sync` load balancing

### Links

- [Synapse-Docker-Compose](https://github.com/tommytran732/Synapse-Docker-Compose)

- [Matrix-org Synapse Docker Compose Workers](https://github.com/matrix-org/synapse/tree/develop/contrib/docker_compose_workers)

- [matrix-conf](https://git.envs.net/envs/matrix-conf/)