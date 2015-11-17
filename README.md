Description
===========

mod_muc_post is an ejabberd module that listens for the muc_filter_message event , and sends the details of he message via HTTP POST to another service. 
This allows ejabberd to alert external services when required.
The main use of such a module is to use a the external service to send push notifications to the user's device.


Supports
========

- ejabberd 15.10

Installation
============

Make sure that ejabberd is already installed. The build script assumes it's under /usr/lib/ejabberd

- git clone https://github.com/zivgabel/mod_muc_post.git
- cd mod_muc_post
- ./build.sh
- sudo cp ebin/*.beam /usr/lib/ejabberd/ebin
- Update the configuration in EJABBERD_HOME/config/ejabberd.yml and restart ejabberd

Example Configuration
=====================

    %%%   =======
    %%%   MODULES

	modules
	..
	..
	  mod_muc_post:
	   post_url: "http://example.com/NewMessage.php"
	..
	..


