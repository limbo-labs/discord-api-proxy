# Discord API Proxy
A transparent, Redis backed proxy for handling Discord's API ratelimits. Designed for use in any distributed environment that needs to interact with the Discord API, this service will centralize and nicely handle all the ratelimiting for your client applications.

## Usage

The easiest way to run the proxy for yourself is Docker, images are available [here](https://hub.docker.com/r/limbolabs/discord-api-proxy).

```bash
docker run -d \
  -p 8080:8080 \
  -e HOST=0.0.0.0 \
  -e REDIS_HOST=redis \
  limbolabs/discord-api-proxy
```

Once up and running, just send your normal requests to `http://YOURPROXY/api/v*` instead of `https://discord.com/api/v*`.

You'll get back all the same responses, except when you would have hit a ratelimit - then you'll get a 429 from the proxy with `x-sent-by-proxy` and `x-ratelimit-bucket` headers as well as the usual ratelimiting headers.

## Metrics

Metrics are enabled by default and can be accessed at `/metrics` on the proxy. They are exposed in the Prometheus format.

#### Environment Variables
| Name                       | Description                                                                                                                                                                                                                                                                                                 |
| -------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `HOST`                     | The host to listen on. Defaults to `127.0.0.1`.                                                                                                                                                                                                                                                             |
| `PORT`                     | The port to listen on. Defaults to `8080`.                                                                                                                                                                                                                                                                  |
| `DISABLE_HTTP2`            | Whether to disable HTTP/2 support. Defaults to `true`.                                                                                                                                                                                                                                                      |
| `REDIS_HOST`               | The host of the Redis server. Defaults to `127.0.0.1`.                                                                                                                                                                                                                                                      |
| `REDIS_PORT`               | The port of the Redis server. Defaults to `6379`.                                                                                                                                                                                                                                                           |
| `REDIS_USER`               | The host of the Redis server. Defaults to an empty string, is only available on Redis 6+.                                                                                                                                                                                                                   |
| `REDIS_PASS`               | The host of the Redis server. If unset, auth is disabled.                                                                                                                                                                                                                                                   |
| `REDIS_POOL_SIZE`          | The size of the Redis connection pool. Defaults to `64`. Note: At least one connection is always reserved for PubSub.                                                                                                                                                                                       |
| `REDIS_SENTINEL`           | Whether to enable Redis Sentinel support. Defaults to `false`.                                                                                                                                                                                                                                              |
| `REDIS_SENTINEL_MASTER`    | The name of the Redis Sentinel master. Defaults to `mymaster`.                                                                                                                                                                                                                                              |
| `LOCK_WAIT_TIMEOUT`        | Duration (in ms) a request should wait for a lock to be released before retrying. Defaults to `500`.                                                                                                                                                                                                        |
| `RATELIMIT_ABORT_PERIOD`   | If the proxy does ever hit a 429, the duration (in ms) it should abort all incoming requests with a 503 for this amount of time. Defaults to `1000`.                                                                                                                                                        |
| `GLOBAL_TIME_SLICE_OFFSET` | The offset (in ms) to add to the global ratelimit's 1s fixed window to make up for the round trip to Discord. You probably don't want to mess with this unless you have a very high ping to the API. Defaults to `200`.                                                                                     |
| `DISABLE_GLOBAL_RATELIMIT` | Whether to disable the global ratelimit checks, only use this if you're sure you won't hit it. Defaults to `false`.                                                                                                                                                                                         |
| `BUCKET_TTL`               | How long the proxy will cache bucket info for. Set to `0` to store forever, but this isn't recommended. Defaults to `86400000` (24h), except for interaction buckets (Ignores this value, always 15 minutes). If trying to save memory consider using `maxmemory` and `allkeys-lru` on your Redis instance. |
| `METRICS_TTL`              | Duration (in ms) after which to reset the metric counters. Defaults to 86400000 (24 hours).                                                                                                                                                                                                                 |

## Warnings

### HTTP2 Connection Drops
These are caused by the underlying HTTP library, see https://github.com/hyperium/hyper/issues/2500. If you're seeing errors, you should use the `DISABLE_HTTP2` environment variable until the linked issue is resolved.

### Redis Latency
The API proxy relies on Redis to store ratelimiting information, so keeping the latency between proxy nodes and Redis as low as possible is crucial.

If the ratelimit check takes longer than is safe, it will first be retried a few times to account for brief latency spikes (these can be common, especially depending on your Redis configuration/hosting environment, but are not a problem).
If the check still fails, the request will be aborted with a 503 + `x-sent-by-proxy` header.

Warnings about latency spikes are generally fine, but if it starts to cause requests to fail [check out this page](https://redis.io/docs/management/optimization/latency/).

## Credits
  - [Nirn Proxy](https://github.com/germanoeich/nirn-proxy) by [@germanoeich](https://github.com/germanoeich) - Used as a reference for bucket mappings
  
