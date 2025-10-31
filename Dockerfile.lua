FROM openresty/openresty:alpine

RUN rm /usr/local/openresty/nginx/conf/nginx.conf || true

COPY ./nginx_lua.conf /usr/local/openresty/nginx/conf/nginx.conf

COPY ./check_limit.lua /etc/nginx/check_limit.lua
