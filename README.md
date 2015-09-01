# QQ_oauth2.0
Lua module to add QQ oauth to nginx

#Ubuntu

You will need to install the following packages.

lua5.1
liblua5.1-0
liblua5.1-0-dev

You will also need to download and build the following and link them with nginx

ngx_devel_kit
lua-nginx-module

#Configuration

	server {
		location /qq {
			default_type 'text/plain; charset=utf-8';

			set $client_id      'your_id';
			set $client_secret	'your_secret';
			set $redirect_uri   'http://your redirect uri';

			access_by_lua_file '/path/of/qq_oauth.lua';
		}

		location QQ {
			internal;
			proxy_set_header   Accept-Encoding ''; #close gzip 

			rewrite ^QQ(.*) $1 break;
			proxy_pass https://graph.qq.com;
		}
	}
