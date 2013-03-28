Tiny Desk Concerts Roku app
===========================

Setup
-----

Put your Roku into [Dev Mode](http://sdkdocs.roku.com/display/RokuSDKv48/Developer+Guide#DeveloperGuide-71EnablingDevelopmentModeonyourbox).

Set the following variables in your `.bash_profile`:

```
export NPR_API_KEY="SUPERUSER_KEY_HERE"
export ROKU_IP="10.0.1.2"
```

You need a superuser API key for this. Sorry, non-NPR people looking at this code. Your Roku will tell you its IP address when you put it into Dev Mode.

Install the Python requirements:

```
$ mkvirtualenv nproku
$ pip install requirements.txt
```

Generate JSON feed
------------------

You will need `s3cmd` installed and configured with the `nprapps` AWS keys in order to deploy the feed.

To generate (and deploy) the Tiny Desk API feed:

```
$ workon nproku
$ python fetch_feed.py
```

Package & Deploy
----------------

To package up the code and deploy it to your Roku:

```
$ ./build.sh
```

Enjoy!

Debugging
---------

To connect to your Roku for debugging:

```
$ telnet $ROKU_IP 8085
```
