--  Returned ratelimit status can be:
--  - False/Nil: Ratelimit not found, must be fetched.
--  - 0: Ratelimit exceeded.
--  - 1-Infinity: Ratelimit OK, is number of requests in current bucket.
--  
--  Takes one Key: 
--  - Bucket ID
-- 
--  Returns the bucket ratelimit status.
--  - bucket_ratelimit_status

local function increment_route_count(key)
    local route_count = tonumber(redis.call('INCR', key))
    
    if route_count == 1 then
        redis.call('EXPIRE', key, 60)
    end

    return route_count
end

local route_key = KEYS[1]
local route_count_key = route_key .. ':count'

local lock_token = ARGV[1]

local route_limit = tonumber(redis.call('GET', route_key))

local holds_route_lock = false
if route_limit == nil then
    holds_route_lock = lock_bucket(route_key, lock_token)

    if holds_route_lock == false then
        return 3
    end
end

if route_count > route_limit then
    local reset_after = redis.call('PTTL', route_key .. ':reset_after')

    if reset_after ~= -2 then
        local reset_at = redis.call('PEXPIRETIME', route_count_key)

        return {2, route_limit, reset_at, reset_after} 
    end

    holds_route_lock = lock_bucket(route_key, lock_token)

    if holds_route_lock == false then
        return 3
    end
end

local holds_global_lock = false
return {5, holds_global_lock, holds_route_lock}