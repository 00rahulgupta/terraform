 #!bin/bash
apt update -y
apt install apache2 -y 
service apache2 restart   
echo "deployed by Terraform" > /var/www/html/index.html
