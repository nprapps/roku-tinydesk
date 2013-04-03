Tiny Desk Concerts Roku app
===========================

Setup
-----

Put your Roku into [Dev Mode](http://sdkdocs.roku.com/display/RokuSDKv48/Developer+Guide#DeveloperGuide-71EnablingDevelopmentModeonyourbox).

Your Roku will tell you its IP address when you put it into Dev Mode. Set it in your `.bash_profile`:

```
export ROKU_IP="10.0.1.2"
```

Install the Python requirements:

```
$ mkvirtualenv roku-tinydesk
$ pip install requirements.txt
```

Generate JSON feed
------------------

**This step is not necessary to run the app.**

To regenerate the API feed you will need a superuser NPR API key and our AWS keys. Set the API key in your `.bash_profile` like so:

```
export NPR_API_KEY="SUPERUSER_KEY_HERE"
```

Install `s3cmd` and configure it with the `nprapps` AWS keys:

```
$ s3cmd --configure
```

To generate (and deploy) the Tiny Desk API feed:

```
$ workon roku-tinydesk 
$ ./fetch_feed.py
```

Package & Deploy
----------------

To package up the code and deploy it to your Roku:

```
$ ./build.sh
```

Enjoy!

Distribute the app
------------------

Distributing the app to Roku requires jumping through additional hoops. First, you'll need to generate crypotgraphic keys on your Roku. Do this like so:

```
$ telnet $ROKU_IP
> genkey
```

Your password will be print out: **save it**. Exit the telnet session by typing `quit`.

Add this new password to your `~/.bash_profile`:

```
export ROKU_PASSWORD="YOUR_PASSWORD_HERE"
```

Now to generate a shippable zip, simply run:

```
$ ./ship.sh 1.0
```

You must supply a version number as the first argument.

Now take your new package and upload it at: [https://owner.roku.com/Developer/Apps/Packages/23962](https://owner.roku.com/Developer/Apps/Packages/23962)

Debugging
---------

To connect to your Roku for debugging:

```
$ telnet $ROKU_IP 8085
```

Google Analytics
----------------

The following events are tracked in Google Analytics:

|Category|Action|Label|Value|Custom 1|Custom 2|
|--------|------|-----|-----|--------|--------|
|Tiny Desk|Startup|||||
|Tiny Desk|Shutdown||`sessionDuration`|`numWatched`|`numFinished`|
|Tiny Desk|Start|`title`||||
|Tiny Desk|Continue|`title`||||
|Tiny Desk|Finish|`title`||||
|Tiny Desk|Stop|`title`|`playtime`|||
|Tiny Desk|Search|`term`||||

**Notes**:

* The *Shutdown* action isn't recorded until the next time the application is run, because there is no reliable shutdown event in a Roku app. As a result, `sessionDuration` will always be approximate. 
* The *Stop* action is reported alongside the *Finish* action when a video is completed, for purposes of tracking playtimes.
* There is no concept of a *ping* in this event model, so users will appear inactive on the Google Analytics dashboard while in the middle of a long video or sitting on a menu. Their `sessionDuration` recorded in the *Shutdown* event will correctly include the this time.

Code conventions
----------------

Because Roku dev lacks strong (or any) code conventions, I'm defining my own.

**Syntax**

* Constants: `UPPERCASE`
* Variables, public members and public functions: `camelCase`
* Objects/Constructors: `TitleCase`
* Public member functions: `GridScreen.refreshLists = GridScreen_refreshLists`
* Private member functions `GridScreen._initLists = _GridScreen_initLists`
* Private member vars: `_underscorePrefixed`
* Keywords: lowercase, e.g. `function` and `end function`

All rules for function names also apply when calling case-insensitive built-in functions, e.g. `createObject()` and `count()`.

**Code organization**

Leave a line of whitespace after `function` and before `end function`

Never use `sub`. Always use `function`.

**Classes**

In class constructors define the class object as `this`. In member functions redefine the class object as `this = m`. *Never* use `m` to refer to the global namespace.

**Comments**

Comments describing a functions purpose should *precede* the function defintion.

Modules should begin with a block comment explaning their purpose:

```
'
' Explainer goes here
'

function main()
    blah blah
```
