FROM nginx:1.25

WORKDIR /usr/share/nginx/html
COPY . .

EXPOSE 80
