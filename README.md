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

Google Analytics
----------------

The following events are tracked in Google Analytics:

|Category|Action|Label|
|--------|------|-----|
|Tiny Desk|Startup|| 
|Tiny Desk|Shutdown|| 
|Tiny Desk|Start|Title|
|Tiny Desk|Continue|Title|
|Tiny Desk|Finish|Title|
|Tiny Desk|Stop|Title|

TODO:

* Search
* Play time
* Number of videos watched
* Rewatched
* Paused

Code conventions
----------------

Because Roku dev lacks strong (or any) code conventions, I'm defining my own:

* Objects/Constructors: `TitleCase`
* Members or public functions: `camelCase`
* Public member functions: `GridScreen.refreshLists = GridScreen_refreshLists`
* Private member functions `GridScreen._initLists = _GridScreen_initLists`
* Private member vars: `_underscorePrefixed`
* Constants: `UPPERCASE`
* Keywords: lowercase, e.g. `function` and `end function`

All rules for function names also apply when calling case-insensitive built-in functions, e.g. `mid()` not `Mid()` and `count()` not `Count()`

Leave a line of whitespace after `function` and before `end function`

Comments describing a functions purpose should *precede* the function defintion.

In class constructors define the class object as `this`. In member functions redefine the class object as `this = m`.

Never use `sub`. Always use `function`.

Modules should begin with a block comment explaning their purpose:

```
'
' Explainer goes here
'

function main()
    blah blah
```
