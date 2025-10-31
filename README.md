# Nginx 처리율 제한 실습

이 프로젝트는 Nginx를 활용한 두 가지 처리율 제한 기법(토큰 버킷, 슬라이딩 윈도우)을 실습합니다.

## 1. 토큰 버킷 처리율 제한 실습 (Nginx 기본 모듈)

### 개요
Nginx의 `limit_req_zone` 및 `limit_req` 지시어를 사용하여 토큰 버킷(Token Bucket) 알고리즘 기반의 처리율 제한을 구현합니다. 이는 설정된 `rate`에 따라 요청을 처리하며, `burst`를 통해 일시적으로 허용되는 초과 요청 수를 조절합니다.

### 사용 파일
- `Dockerfile`: Nginx 이미지를 빌드하고 `nginx.conf`를 복사합니다.
- `nginx.conf`: Nginx 처리율 제한 설정을 포함합니다.
- `run.sh`: Docker 이미지를 빌드하고 Nginx 컨테이너를 실행하며, 처리율 제한 테스트 요청을 보냅니다.

### 실습 방법

1.  **프로젝트 클론 및 이동**:
    ```bash
    git clone https://github.com/your-repo/rate-limit-nginx.git
    cd rate-limit-nginx
    ```

2.  **실습 실행**:
    `run.sh` 스크립트를 실행하여 Docker 환경을 설정하고 테스트를 진행합니다.
    ```bash
    ./run.sh
    ```
    이 스크립트는 다음 작업을 수행합니다:
    - `Dockerfile`을 사용하여 `rate-limit-lab` 이미지를 빌드합니다.
    - `nginx.conf` 설정을 가진 Nginx 컨테이너를 8080 포트로 실행합니다.
    - `/api/token` 엔드포인트에 여러 요청을 보내 토큰 버킷 처리율 제한 동작을 확인합니다.
    - 테스트 완료 후 컨테이너를 정리합니다.

3.  **결과 확인**:
    스크립트 실행 후 터미널에 출력되는 HTTP 응답 코드(200, 429) 및 시간 정보를 통해 처리율 제한 동작을 확인할 수 있습니다. `burst` 설정에 따라 초과된 요청은 즉시 429 응답을 받거나, 토큰이 채워질 때까지 지연될 수 있습니다 (이 예제에서는 `nodelay` 옵션으로 즉시 429 응답).

### Nginx 설정 (`nginx.conf`) 주요 내용

```nginx
# ... (생략) ...
http {
    # ... (생략) ...
    limit_req_zone "$remote_addr$http_user_agent" zone=api_limit_zone:10m rate=1r/s;

    server {
        listen 80;

        location /api/token {
            limit_req zone=api_limit_zone burst=3 nodelay;
            proxy_pass http://127.0.0.1:80/ok_token;
        }

        location @429_response {
            return 429 "Too Many Requests\n";
        }
    }
}
```

- `limit_req_zone`: `api_limit_zone`이라는 이름으로 10MB 메모리 영역을 할당하고, 초당 1개의 요청(`rate=1r/s`)을 허용합니다. 클라이언트 식별은 `$remote_addr$http_user_agent`를 사용합니다.
- `limit_req zone=api_limit_zone burst=3 nodelay`: `/api/token` 엔드포인트에 `api_limit_zone`을 적용합니다. `burst=3`은 초과되는 3개의 요청까지는 버킷에 저장했다가 처리하고, `nodelay`는 버킷에 토큰이 없을 경우 요청을 지연시키지 않고 즉시 429 응답을 반환하도록 합니다.

## 2. 슬라이딩 윈도우 처리율 제한 실습 (Nginx + Lua + Redis)

### 개요
OpenResty(Nginx + Lua)와 Redis를 활용하여 슬라이딩 윈도우(Sliding Window) 알고리즘 기반의 처리율 제한을 구현합니다. Lua 스크립트를 통해 Redis에 요청 타임스탬프를 저장하고, 지정된 시간 윈도우 내의 요청 수를 계산하여 처리율을 제어합니다.

### 사용 파일
- `Dockerfile.lua`: OpenResty 이미지를 빌드하고 `nginx_lua.conf` 및 `check_limit.lua`를 복사합니다.
- `nginx_lua.conf`: OpenResty(Nginx) 설정 파일로, Lua 스크립트를 로드하고 실행하여 처리율 제한 로직을 적용합니다.
- `check_limit.lua`: Redis에 저장된 요청 타임스탬프를 관리하고 처리율을 계산하는 Lua 스크립트입니다.
- `run_lua_test.sh`: Docker 네트워크, Redis 컨테이너, OpenResty 컨테이너를 설정하고 슬라이딩 윈도우 처리율 제한 테스트 요청을 보냅니다.

### 실습 방법

1.  **프로젝트 클론 및 이동**:
    ```bash
    git clone https://github.com/your-repo/rate-limit-nginx.git
    cd rate-limit-nginx
    ```

2.  **실습 실행**:
    `run_lua_test.sh` 스크립트를 실행하여 Docker 환경을 설정하고 테스트를 진행합니다.
    ```bash
    ./run_lua_test.sh
    ```
    이 스크립트는 다음 작업을 수행합니다:
    - Docker 네트워크를 생성합니다.
    - Redis 컨테이너를 실행합니다.
    - `Dockerfile.lua`를 사용하여 `nginx-lua-lab` 이미지를 빌드합니다.
    - `nginx_lua.conf` 및 `check_limit.lua` 설정을 가진 OpenResty 컨테이너를 8080 포트로 실행합니다.
    - `/api/` 엔드포인트에 여러 요청을 보내 슬라이딩 윈도우 처리율 제한 동작을 확인합니다.
    - 테스트 완료 후 모든 컨테이너와 네트워크를 정리합니다.

3.  **결과 확인**:
    스크립트 실행 후 터미널에 출력되는 HTTP 응답 코드(200, 429) 및 X-RateLimit-Limit, X-RateLimit-Remaining 헤더를 통해 처리율 제한 동작을 확인할 수 있습니다. Redis에 저장된 타임스탬프가 윈도우 밖으로 밀려나면(슬라이딩 윈도우) 다시 요청이 허용되는 것을 볼 수 있습니다.

### OpenResty 설정 (`nginx_lua.conf`) 주요 내용

```nginx
# ... (생략) ...
http {
    # ... (생략) ...
    lua_shared_dict redis_scripts 1m;

    init_worker_by_lua_block {
        -- check_limit.lua 스크립트를 Redis에 로드하고 SHA1 해시를 공유 딕셔너리에 저장
    }

    server {
        listen 80;

        location /api/ {
            content_by_lua_block {
                -- Redis에서 SHA1 해시를 가져와 check_limit.lua 스크립트 실행
                -- 요청 수, 윈도우 크기, 제한 값 설정
                local limit = 5
                local window_ms = 10000 -- 10초
                local now_ms = ngx.now() * 1000
                local key = "rate_limit:" .. ngx.var.remote_addr

                local result, err = red:evalsha(sha, 1, key, now_ms, window_ms, limit)

                -- 결과에 따라 429 또는 200 응답 반환 및 RateLimit 헤더 설정
            }
        }

        location @429_response {
            return 429 "Too Many Requests\n";
        }
    }
}
```

- `lua_shared_dict redis_scripts 1m`: Lua 스크립트의 SHA1 해시를 저장하기 위한 공유 메모리 공간을 1MB 할당합니다.
- `init_worker_by_lua_block`: Nginx 워커 프로세스 시작 시 `check_limit.lua` 스크립트를 Redis에 로드하고, 반환된 SHA1 해시를 `redis_scripts` 공유 딕셔너리에 저장합니다. 이를 통해 매 요청마다 스크립트를 로드하는 오버헤드를 줄입니다.
- `content_by_lua_block`: `/api/` 엔드포인트에 대한 요청이 들어올 때마다 실행되는 Lua 블록입니다. Redis에 연결하고, 공유 딕셔너리에 저장된 SHA1 해시를 사용하여 `check_limit.lua` 스크립트를 `evalsha` 명령으로 실행합니다. `check_limit.lua`는 지정된 `window_ms` (예: 10초) 내에서 `limit` (예: 5개)를 초과하는 요청에 대해 429 응답을 반환합니다.

### Lua 스크립트 (`check_limit.lua`) 주요 내용

```lua
-- check_limit.lua (Redis Script)
-- KEYS[1]: rate_limit key (e.g., "rate_limit:192.168.1.1")
-- ARGV[1]: current timestamp in milliseconds
-- ARGV[2]: window size in milliseconds
-- ARGV[3]: limit

local key = KEYS[1]
local now_ms = tonumber(ARGV[1])
local window_ms = tonumber(ARGV[2])
local limit = tonumber(ARGV[3])

-- 현재 윈도우 밖의 오래된 타임스탬프 제거
redis.call("ZREMRANGEBYSCORE", key, 0, now_ms - window_ms)

-- 현재 요청 타임스탬프 추가
redis.call("ZADD", key, now_ms, now_ms)

-- TTL 설정 (선택 사항, Redis 키가 영구적으로 남는 것을 방지)
redis.call("EXPIRE", key, math.ceil(window_ms / 1000) + 1)

-- 현재 윈도우 내의 요청 수 반환
return redis.call("ZCARD", key)
```

- 이 Lua 스크립트는 Redis의 Sorted Set을 활용하여 슬라이딩 윈도우를 구현합니다.
- `ZREMRANGEBYSCORE`: 현재 타임스탬프에서 `window_ms`를 뺀 시간보다 작은 스코어(오래된 타임스탬프)를 가진 멤버들을 Sorted Set에서 제거합니다. 이는 윈도우가 '슬라이딩'하는 효과를 만듭니다.
- `ZADD`: 현재 요청의 타임스탬프를 스코어와 멤버로 Sorted Set에 추가합니다.
- `EXPIRE`: Redis 키에 TTL(Time-To-Live)을 설정하여, 처리율 제한 정보가 일정 시간 후에 자동으로 만료되도록 합니다.
- `ZCARD`: 현재 Sorted Set에 남아있는 멤버(요청)의 수를 반환하여, 지정된 윈도우 내의 총 요청 수를 알려줍니다.
