local global_count_key = KEYS[1] .. ':count'
local global_expire_at = tonumber(ARGV[1])

redis.call('PEXPIREAT', global_count_key, global_expire_at, 'LT')