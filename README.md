# Akamai G2O in LUA


Signature Header Authentication (aka G2O) is a mechanism that allows the backend infrastructure to ensure that requests are coming from a trusted source, the Akamai Platfom specifically.

This is extract from the documentation:

> This feature configures edge servers to include two special headers in requests to the origin server. One of these headers contains basic information about the specific request. The second header contains similar information encrypted with a shared secret. This allows the origin server to perform several levels of authentication to ensure that the request is coming directly from an edge server without tampering.

# Why LUA?

G2O validation can generally be implemented in two places:

* Web Application
* Web Server / Load Balancer like HAProxy or NGINX

Excellent example of the intergration within Web Application was done by @ynohat (<https://github.com/ynohat/akamai-g2o>).  
I didn't find much implementations for Web Servers and Load Balancers, and all of the existing solution require to compile the code which can generate some maintenance overhead.  
Some servers just do not support dynamic modules at all (i.e. HAProxy) which requires to patch and build from source. Definitely not making the life easier.

However, top open-source servers like HAProxy, NGINX, Apache and Varnish - do support LUA language.  
LUA is a very popular lightweight embeddable scripting language, and what is great - single codebase can be used across multiple vendors. 

# Components

Project consist of a single library responsible for G2O validation, and connectors for multiple vendors.  
The library is pretty generic and has external dependency on *libossl* (<https://github.com/wahern/luaossl>).  
The connectors are vendor specific and their responsibility is to ease the library integration.


# How to install

## Prerequisites

G2O validation requires **luaossl** library which can be installed with *luarocks*.  
Please refer to your distribution documentation regarding installation steps.

### Ubuntu 18.04

```bash
apt install luarocks libssl-dev
luarocks install luaossl
```

### CentOS

Add `epel` repository and install lua packages:

```bash
yum install epel-release
yum install luarocks openssl-devel lua-devel gcc
luarocks install luaossl
```

## HAProxy

`akamai-g2o-haproxy-wrapper.lua` registers two functions:

* `g2o_validation_fetch` - which is referred from haproxy frontend section
* `g2o_failure_service` - which is used from haproxy backend when validation fails. It serves 400 response with "Unauthorized Access" response body

*Note: It is assumed that the configuration file and all G2O related files are stored in `/etc/haproxy` path.*

In `/etc/haproxy/haproxy.cfg` within global section add the following line:

```
    lua-load /etc/haproxy/akamai-g2o-haproxy-wrapper.lua
```

add g2o validation to your frontend settings:

```
frontend g2o-example
   bind             :80
   mode             http
   use_backend      %[lua.g2o_validation_fetch(5,"s3cr3tk3y",30,"g2o-failure-backend","g2o-success-backend")]
   default_backend  g2o-failure-backend
   log              127.0.0.1 local1 debug
```

Parameters for `g2o_validation_fetch` are as follows:

* version of G2O
* secret key (same like in Akamai configuration file)
* time delta - acceptable time margin for timestamp validation
* failure backend - which backend to go when G2O validation failed
* success backend - which backend to go when G2O validation succeeds

Now let's define the backends:

```
backend g2o-success-backend
   balance  roundrobin
   server   web1 X.X.X.X:80
   log      127.0.0.1 local1 debug

backend g2o-failure-backend
   http-request use-service lua.g2o_failure_service
   log          127.0.0.1 local1 debug
```

It is possible to enable G2O validation is soft-mode, so requests with invalid G2O signature will not be rejected, however proper warning will be logged. This can be done by using the same backend for failure and success actions:

```
   use_backend      %[lua.g2o_validation_fetch(5,"s3cr3tk3y",30,"g2o-success-backend","g2o-success-backend")]
```

## NGINX

Download g2o wrapper and library to `/etc/nginx/lua` folder:

```bash
mkdir /etc/nginx/lua
wget -P /etc/nginx/lua https://raw.githubusercontent.com/lukaszczerpak/akamai-g2o-lua/master/akamai-g2o-nginx-wrapper.lua
wget -P /etc/nginx/lua https://raw.githubusercontent.com/lukaszczerpak/akamai-g2o-lua/master/akamai-g2o.lua
```


Enable lua module in `/etc/nginx/nginx.conf` first:

```
load_module modules/ngx_http_lua_module.so;
```

and initialize the connector in `server` section:

```
http {
    ...
    
    lua_package_path "/etc/nginx/lua/?.lua;;";
    init_by_lua_block { require "akamai-g2o-nginx-wrapper" }
}
```

G2O can be enabled for certain paths or entire site in the following way:

```
  location / {
     access_by_lua_block { akamai_g2o_validate_nginx(5, "s3cr3tk3y", 30) }
  }
```

Parameters for `akamai_g2o_validate_nginx()` are as follows:

* version of G2O
* secret key (same like in Akamai configuration file)
* time delta - acceptable time margin for timestamp validation

## Apache (CentOS)

Download g2o wrapper and library to `/etc/httpd/lua` folder:

```bash
mkdir /etc/httpd/lua
wget -P /etc/httpd/lua https://raw.githubusercontent.com/lukaszczerpak/akamai-g2o-lua/master/akamai-g2o-apache-wrapper.lua
wget -P /etc/httpd/lua https://raw.githubusercontent.com/lukaszczerpak/akamai-g2o-lua/master/akamai-g2o.lua
```

Ensure `mod_lua` is enabled in Apache (it is by default):

```
LoadModule lua_module modules/mod_lua.so
```

In the apache configuration, you need to declare the following:

- default location of lua scripts
- authz provider
- paths to be validated against g2o

Sample configuration snippet:

```
LuaRoot /etc/httpd/lua
LuaAuthzProvider akamai_g2o akamai-g2o-apache-wrapper.lua akamai_g2o_validate_apache
<Location "/">
  Require akamai_g2o 5 "s3cr3tk3y" 30
</Location>
```

# Contribution

If your server is not listed and supports LUA then you are more than welcome to contribute and implement the connector :)


# Testing

The G2O validation has unit tests which can be run with the following command (<https://olivinelabs.com/busted/>):

```sh
❯❯❯ busted akamai-g2o_spec.lua
●●●●●●●●●
9 successes / 0 failures / 0 errors / 0 pending : 0.057342 seconds
```

