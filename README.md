nproku
======

Any experiment. Borrows code from the Roku example apps and from [https://github.com/brianboyer/feedtv](https://github.com/brianboyer/feedtv)

Setup
-----

Get the [Roku SDK](http://www.roku.com/developer).

Put your Roku into [Dev Mode](http://sdkdocs.roku.com/display/RokuSDKv48/Developer+Guide#DeveloperGuide-71EnablingDevelopmentModeonyourbox).

Set the following variables in your `.bash_profile`:

```
export NPR_API_KEY="SUPERUSER_KEY_HERE"
export ROKU_IP="10.0.1.2"
```

You need a superuser API key for this. Sorry, non-NPR people looking at this code.

Lastly, install the Python requirements:

```
$ mkvirtualenv nproku
$ pip install requirements.txt
```

Generate JSON feed
------------------

To generate the Tiny Desk API feed:

```
$ workon nproku
$ python fetch_feed.py
```

Package & Deploy
----------------

Do it!

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
