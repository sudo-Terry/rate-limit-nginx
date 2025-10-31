# Stop on any error
set -e

# 환경변수
NETWORK_NAME="rate-limit-net"
REDIS_NAME="redis-server"
NGINX_LUA_IMAGE="nginx-lua-lab"
NGINX_LUA_NAME="nginx-lua-server"

# 1. 시작
echo "--- Cleaning up previous runs ---"
docker stop $NGINX_LUA_NAME >/dev/null 2>&1 || true
docker rm $NGINX_LUA_NAME >/dev/null 2>&1 || true
docker stop $REDIS_NAME >/dev/null 2>&1 || true
docker rm $REDIS_NAME >/dev/null 2>&1 || true
docker network rm $NETWORK_NAME >/dev/null 2>&1 || true
echo "Cleanup complete."

# 2. Docker network 생성
echo "\n--- Creating Docker network ---"
docker network create $NETWORK_NAME
echo "Network '$NETWORK_NAME' created."

# 3. Redis 컨테이너 실행
echo "\n--- Starting Redis container ---"
docker run -d --name $REDIS_NAME --network $NETWORK_NAME redis:alpine
echo "Redis container '$REDIS_NAME' started."

# 4. OpenResty Docker 이미지 빌드
echo "\n--- Building OpenResty image ---"
docker build -t $NGINX_LUA_IMAGE -f Dockerfile.lua .
echo "Image '$NGINX_LUA_IMAGE' built."

# 5. OpenResty container
echo "\n--- Starting OpenResty container ---"
docker run -d --name $NGINX_LUA_NAME --network $NETWORK_NAME -p 8080:80 $NGINX_LUA_IMAGE
echo "OpenResty container '$NGINX_LUA_NAME' started on port 8080."

# 서비스 시작 대기
echo "\n--- Waiting for services to start ---"
sleep 5 # Give redis and nginx time to start

# 6. 요청
echo "\n--- Running Sliding Window test (limit: 5 requests per 10 seconds) ---"
for i in {1..7}; do
  echo "\n--- Request $i ---"
  curl -i http://localhost:8080/api/
  sleep 1
done

# 7. 대기
echo "\n--- Waiting 5 seconds for window to slide... ---"
sleep 5

# 8. 슬라이딩 윈도우 움직이고 난 뒤에 요청 
echo "\n--- Request 8 (after window slide) ---"
curl -i http://localhost:8080/api/

# 9. 종료
echo "\n\n--- Cleaning up ---"
docker stop $NGINX_LUA_NAME
docker stop $REDIS_NAME
docker network rm $NETWORK_NAME
echo "All done."
