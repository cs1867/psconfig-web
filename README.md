# perfSONAR Meshconfig Administartor

MeshConfig Administrator GUI and tools to publish generated meshconfig

## Installation

### VM Host

To install MCA, you will need an empty VM with any OS that supports later version of Docker, such as Centos7

Creation of VM is out of scope of this document, but we recommend following specification.

* 4-8 CPUs
* 4G memory
* 8G disk

>! Note for GOC Staff `devm06 $ mkvm -c 4 -m 4G -p -r c7 meshconfig-itb.3`

Make sure you have the latest RPMs

`yum update`

### Docker Engine

Follow the official [docker installation doc](https://docs.docker.com/engine/installation/) (not from the RHEL repo) to install docker engine.

For CentOS7..

```
$ sudo yum-config-manager \
    --add-repo https://docs.docker.com/engine/installation/linux/repo_files/centos/docker.repo
$ sudo yum check-update
$ sudo yum install docker-engine
```

Before you start the docker engine, you might want to add VM specific configuration. For example, your VM might be using /usr/local to store most of the data (like at GOC), then you should have something like following in /etc/docker/daemon.json


```
{
        "graph": "/usr/local/docker"
}

```

Finally, enable & start docker engine

```
$ systemctl enable docker
$ systemctl start docker
```

### Configuration

Before you install MCA, you should prepare your set of configuration file. You can bootstrap it by
downloading and deploying MCA's default configuration files from here

```bash
wget https://somewhere.com/mca_config.tar.gz
tar -xzf mca_config.tar.gz -C /etc
```

1. Authentication Service API Configration

Edit /etc/mca/auth/index.js

```json
exports.email_confirmation = {
    subject: 'Meshconfign Account Confirmation',
    from: 'hayashis@iu.edu',  //most mail server will reject if this is not eplyable address
};

```

If you'd like to skip email confirmation after user signup, simply comment out the whole section. Otherwise, update `from` address to whoever you want the email confirmation to be sent. 

2. 






You should see...

```
TODO
TODO
TODO
TODO
TODO
TODO
TODO
TODO
TODO
TODO
TODO
TODO
```

#### Host Certificates

You will need SSL certificates to run nginx. Inside /etc/grid-security/host, you should see your host certificate with following file names.

```
$ ls /etc/grid-security/host
cert.pem 
key.pem
ca.pem
```

If not, please request for new certificate.

### Container Installation

1. Create a docker network to group all MCA containers (so that you don't have --link them)

```
$ sudo docker network create mca
```

2. Create mongoDB container. Use -v to persist data on host directory (/usr/local/data/mongo) 

```bash
mkdir -p /usr/local/data
sudo docker run \
        --restart=always \
        --net mca \
        --name mongo \
        -v /usr/local/data/mongo:/data/db \
        -d mongo
```

3. Create SCA authentication service container. This service handles user authentication / account/user group management.

```bash
sudo docker run \
    --restart=always \
    --net mca \
    --name sca-auth \
    -v /etc/mca/auth:/app/api/config \
    -v /usr/local/data/auth:/db \
    -d soichih/sca-auth
```

> sca-auth container will generate a few files under /config directory when it's first started, so don't mount it with `ro`.
> I am persisting the user account DB on /usr/local/data/auth.

4. Create MCA's main UI/API container.

```bash
sudo docker run \
    --restart=always \
    --net mca \
    --name mca-admin1 \
    -v /etc/mca:/app/api/config:ro \
    -d soichih/mca-admin
```

5. Create meshconfig publisher. 

```bash
sudo docker run \
    --restart=always \
    --net mca \
    --name mca-pub1 \
    -v /etc/mca:/app/api/config:ro \
    -d soichih/mca-pub
```

6. Finally, we install nginx to expose these container via 80/443/9443

```bash
sudo docker run \
    --restart=always \
    --net mca \
    --name nginx \
    -v /etc/mca/shared:/shared:ro \
    -v /etc/mca/nginx:/etc/nginx:ro \
    -v /etc/grid-security/host:/certs:ro \
    -p 80:80 \
    -p 443:443 \
    -p 9443:9443 \
    -d nginx
```

Now you should see all 5 containers running.

```bash
$ sudo docker container list
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS                                                              NAMES
42efd21ff7f1        soichih/mca-pub     "node /app/api/mcp..."   18 seconds ago      Up 17 seconds       8080/tcp                                                           mca-pub1
ab3936c7ab8c        soichih/mca-admin   "/start.sh"              19 seconds ago      Up 18 seconds       80/tcp, 8080/tcp                                                   mca-admin1
90cfbb8ba096        soichih/sca-auth    "/app/docker/start.sh"   24 seconds ago      Up 24 seconds       80/tcp, 8080/tcp                                                   sca-auth
aa6471073c01        nginx               "nginx -g 'daemon ..."   11 hours ago        Up 11 hours         0.0.0.0:80->80/tcp, 0.0.0.0:443->443/tcp, 0.0.0.0:9443->9443/tcp   nginx
10fdf3b63e4f        mongo               "/entrypoint.sh mo..."   12 hours ago        Up 12 hours         27017/tcp                                                          mongo
```

### Firewall

Docker will take care of its own firewall rules, so you don't have to worry about opening ports manually. 

However, following are the ports used by nginx container.

* 443 (For MCA administrative GUI)
* 80 (For MCA configuration publisher)
* 9443 (For x509 authentication to MCA administrative GUI)

# Reference

Meshconfig parameters
http://docs.perfsonar.net/config_mesh.html

# TODO

Remove service records that are really old (1 week?)

when a user login for the first time, I should forward user to install ui that does following
1) make the first user login as super admin
2) create sample testspec / hostgroups / config to show user how to get started

Disallow user from used testspecs / hostgroups (and show which config/test uses them)

when config is removed, test records will be orphaned - should be cascaded?

* Prevent user from removing hostgroups / testspecs currently used by a config
* Prevent user from orphaning config / testspecs / hostsgroups by removing all admins

* profile service needs to announce any updates made by user to all other services caching profile info
* Display which config/test users each hostgroup / testspecs
