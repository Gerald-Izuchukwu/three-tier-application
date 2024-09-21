#!/bin/bash


# Update and install Docker
sudo yum update -y >> /var/log/user-data.log 2>&1
sudo yum install -y docker >> /var/log/user-data.log 2>&1

# Start Docker service
sudo systemctl start docker >> /var/log/user-data.log 2>&1

while ! systemctl is-active docker; do sleep 5; done

# docker run -d -p80:80 --name nginx-test nginx

sudo yum install -y nginx >> /var/log/user-data.log 2>&1

# while ! systemctl is-active nginx; do sleep 5; done

cd /etc/nginx/

sudo mv nginx.conf nginx-backup.conf

sudo rm -rf fastcgi_params.default  nginx.conf.default fastcgi.conf.default mime.types.default  uwsgi_params.default  scgi_params.default

# cd /usr/share/nginx/html 

# sudo rm -rf index.html

cd /home/ec2-user
sudo aws s3 cp s3://three-tier-test-app/frontend/ frontend/ --recursive
# sudo cp /home/ec2-user/frontend/public/{countries.html,time.html,health.html,script.js,index.html} /usr/share/nginx/html/
sudo mv /home/ec2-user/frontend/nginx.conf /etc/nginx
sudo chmod -R 755 /home/ec2-user
sudo systemctl start nginx













# combined HTTP AND SERVER FILES
# sudo tee /etc/nginx/nginx.conf > /dev/null <<EOF
# user nginx;
# worker_processes auto;
# error_log /var/log/nginx/error.log notice;
# pid /run/nginx.pid;

# # Load dynamic modules. See /usr/share/doc/nginx/README.dynamic.
# include /usr/share/nginx/modules/*.conf;

# events {
#     worker_connections 1024;
# }

# http {
#     log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
#                       '$status $body_bytes_sent "$http_referer" '
#                       '"$http_user_agent" "$http_x_forwarded_for"';

#     access_log  /var/log/nginx/access.log  main;

#     sendfile            on;
#     tcp_nopush          on;
#     keepalive_timeout   65;
#     types_hash_max_size 4096;

#     include             /etc/nginx/mime.types;
#     default_type        application/octet-stream;

#     # Load modular configuration files from the /etc/nginx/conf.d directory.
#     # See http://nginx.org/en/docs/ngx_core_module.html#include
#     # for more information.
#     include /etc/nginx/conf.d/*.conf;

#     server {
#         listen       80;
#         listen       [::]:80;
#         server_name  _;
#         root         /usr/share/nginx/html;

#         # Load configuration files for the default server block.
#         include /etc/nginx/default.d/*.conf;

#         location / {
#             try_files $uri $uri/ /index.html;
#         }

#         location /time {
#             try_files $uri $uri/ /time.html;
#         }

#         location /countries {
#             try_files $uri $uri/ /countries.html;
#         }

#         location /health {
#             try_files $uri $uri/ /health.html;
#         }


#         error_page 404 /404.html;
#             location = /404.html {
#         }

#         error_page 500 502 503 504 /50x.html;
#             location = /50x.html {
#             }
#     }
    



# }
# EOF




# DIFF HTTP AND SERVER FILES
# cd /home/ec2-user
# sudo aws s3 cp s3://three-tier-test-app/frontend/public frontend/public --recursive
# sudo chown -R nginx:nginx /home/ec2-user
# sudo chmod 755 /home/ec2-user
# sudo chmod 755 /home/ec2-user/frontend
# sudo chmod 755 /home/ec2-user/frontend/public


# sudo tee /etc/nginx/nginx.conf > /dev/null <<EOF
# user  nginx;
# worker_processes  auto;

# error_log  /var/log/nginx/error.log notice;
# pid        /var/run/nginx.pid;

# events {
#     worker_connections  1024;
# }

# http {
#     include       /etc/nginx/mime.types;
#     default_type  application/octet-stream;

#     types_hash_max_size 2048;
#     types_hash_bucket_size 128;

#     log_format  main  '\$remote_addr - \$remote_user [\$time_local] "\$request" '
#                       '\$status \$body_bytes_sent "\$http_referer" '
#                       '"\$http_user_agent" "\$http_x_forwarded_for"';

#     access_log  /var/log/nginx/access.log  main;

#     sendfile        on;
#     #tcp_nopush     on;

#     keepalive_timeout  65;

#     #gzip  on;

#     include /etc/nginx/conf.d/*.conf;
# }
# EOF


# sudo tee /etc/nginx/conf.d/default.conf > /dev/null <<EOF 
# server {
#     listen       80;
#     server_name  localhost;
#     root   /home/ec2-user/frontend/public;
#     index index.html;

#     location / {
#         try_files $uri $uri/ /index.html;
#     }

#     location /time {
#         try_files $uri $uri/ /time.html;
#     }

#     location /countries {
#         try_files $uri $uri/ /countries.html;
#     }

#     location /health {
#         try_files $uri $uri/ /health.html;
#     }

#     error_page   500 502 503 504  /50x.html;
#     location = /50x.html {
#         root   /usr/share/nginx/html;
#     }

# }
# EOF

# sudo systemctl start nginx