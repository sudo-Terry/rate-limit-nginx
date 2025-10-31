local key = KEYS[1]
local now_ms = tonumber(ARGV[1])
local window_ms = tonumber(ARGV[2])
local limit = tonumber(ARGV[3])

local window_start_ms = now_ms - window_ms

redis.call("ZREMRANGEBYSCORE", key, "-inf", "(" .. window_start_ms)

local current_count = redis.call("ZCOUNT", key, "-inf", "+inf")

if current_count >= limit then

    return current_count + 1
end

redis.call("ZADD", key, now_ms, now_ms)

redis.call("EXPIRE", key, math.ceil(window_ms / 1000) + 1)

return current_count + 1