docker build --no-cache -t rate-limit-lab .

docker run -d --rm -p 8080:80 --name nginx-lab rate-limit-lab

# 1초 처리율 제한
# for i in {1..7}; do \
#   curl -w "Leaky | Request: $i | HTTP: %{http_code} | Total Time: %{time_total}s\n" \
#   http://localhost:8080/api/leaky
# done

# # 토큰 버킷 방식 (3)
# for i in {1..7}; do \
#   curl -w "Token | Request: $i | HTTP: %{http_code} | Total Time: %{time_total}s\n" \
#   http://localhost:8080/api/token
# done

# 토큰 버킷 방식 (3) 다음 토큰 채워지면 200인지 확인하기
for i in {1..15}; do
  if [ $i -eq 10 ]; then
    sleep 1
  fi
  curl -w "Token | Request: $i | HTTP: %{http_code} | Total Time: %{time_total}s\n" \
       http://localhost:8080/api/token
done

docker stop nginx-lab