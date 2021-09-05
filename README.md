## Code solution with no GUI involvement and 100% complete automation
Create two custom Dockerfiles : Dockerfile1 and Dockerfile2, create containers from these two dockerfiles and deploy the containers in a new AWS server : with port number 80 and 8080 alone and only 8GB of SSD storage. The new server should be created in a new VPC setup (not in default VPC and  gateways etc ).
Install NGINX as a server on the created new AWS server and deploy the nginx.conf file which uses nginx as a reverse proxy to the two docker containers that you created earlier and will deploy on that server.

In the end you should output the Public IP of the server which should access one of the docker container.

Tools I used : 
1. Github
2. Dockerfile and Docker container
3. Jenkins
4. DockerHUB
5. NGINX Webserver - Reverse Proxy
6. Terraform

![lgLP2UC0Zw](https://user-images.githubusercontent.com/60294234/132136444-beeda26c-d878-4cb1-a1b2-d072cbcd3eb9.gif)

![4uC5Jk6wXZ](https://user-images.githubusercontent.com/60294234/132136437-1c1ad1a4-ba42-466e-8ea7-c2152ff7f31a.gif)

