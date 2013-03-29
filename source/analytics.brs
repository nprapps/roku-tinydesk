'
' Analytics module based on code from the Plex Roku client.
'
' Original code: https://github.com/plexinc/roku-client-public/blob/master/Plex/source/Analytics.brs
' License to use explicitly granted: https://github.com/plexinc/roku-client-public/issues/233#issuecomment-15557688
' The Plex code was itself based on: http://bloggingwordpress.com/2012/04/google-analytics-for-roku-developers/
' Original licenses follows: 
'

REM *****************************************************
REM   Google Analytics Tracking Library for Roku
REM   GATracker.brs - Version 2.0
REM   (C) 2012, Trevor Anderson, BloggingWordPress.com
REM   Permission is hereby granted, free of charge, to any person obtaining a copy of this software
REM   and associated documentation files (the "Software"), to deal in the Software without restriction,
REM   including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,
REM   and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so,
REM   subject to the following conditions:
REM
REM   The above copyright notice and this permission notice shall be included in all copies or substantial
REM   portions of the Software.
REM
REM   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT
REM   LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
REM   IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
REM   WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
REM   SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
REM *****************************************************

function Analytics() as Object

    this = {}

    this.account = "UA-39645840-3"
    this.appName = "roku-tinydesk"
    this.domain = "apps.npr.org"
    this.numEvents = 0
    this.numPlaybackEvents = 0
    this.baseUrl = ""
    
    this.sessionTimer = CreateObject("roTimespan")

    this.startup = Analytics_startup
    this.shutdown = Analytics_shutdown
    this.trackEvent = Analytics_trackEvent
    this._formatEvent = _Analytics_formatEvent
    this._formatCustomVars = _Analytics_formatCustomVars
    this._random = _Analytics_random

    xfer = createObject("roUrlTransfer")
    device = createObjecT("roDeviceInfo")
    screenSize = device.getDisplaySize()

    this.baseUrl = "http://www.google-analytics.com/__utm.gif"
    this.baseUrl = this.baseUrl + "?utmwv=1"
    this.baseUrl = this.baseUrl + "&utmsr=" + screenSize.w.toStr() + "x" + screenSize.h.toStr()
    this.baseUrl = this.baseUrl + "&utmsc=24-bit"
    this.baseUrl = this.baseUrl + "&utmul=en-us"
    this.baseUrl = this.baseUrl + "&utmje=0"
    this.baseUrl = this.baseUrl + "&utmfl=-"
    this.baseUrl = this.baseUrl + "&utmdt=" + xfer.Escape(this.appName)
    this.baseUrl = this.baseUrl + "&utmp=" + xfer.Escape(this.appName)
    this.baseUrl = this.baseUrl + "&utmhn=" + xfer.Escape(this.domain)
    this.baseUrl = this.baseUrl + "&utmr=-"
    this.baseUrl = this.baseUrl + "&utmvid=" + xfer.Escape(device.getDeviceUniqueId())

    ' Initialize our "cookies"
    domainHash = "1024141829" ' should be set by Google, but hardcode to something
    visitorID = RegRead("AnalyticsID", "analytics", invalid)

    if visitorID = invalid then
        visitorID = this._random(1000000000,9999999999).toStr()
        RegWrite("AnalyticsID", visitorID, "analytics")
    end if

    timestamp = createObject("roDateTime")
    firstTimestamp = RegRead("FirstTimestamp", "analytics", invalid)
    prevTimestamp = RegRead("PrevTimestamp", "analytics", invalid)
    curTimestamp = timestamp.asSeconds().toStr()

    RegWrite("PrevTimestamp", curTimestamp, "analytics")

    if prevTimestamp = invalid then prevTimestamp = curTimestamp
    if firstTimestamp = invalid then
        RegWrite("FirstTimestamp", curTimestamp, "analytics")
        firstTimestamp = curTimestamp
    end if

    numSessions = RegRead("NumSessions", "analytics", "0").toint() + 1
    RegWrite("NumSessions", numSessions.toStr(), "analytics")

    this.baseUrl = this.baseUrl + "&utmcc=__utma%3D" + domainHash + "." + visitorID + "." + firstTimestamp + "." + prevTimestamp + "." + curTimestamp + "." + numSessions.toStr()
    this.baseUrl = this.baseUrl + "%3B%2B__utmb%3D" + domainHash + ".0.10." + curTimestamp + "000"
    this.baseUrl = this.baseUrl + "%3B%2B__utmc%3D" + domainHash + ".0.10." + curTimestamp + "000"

    this.sessionTimer.mark()

    return this 

end function

function Analytics_trackEvent(category, action, label, value, customVars)

    this = m

    ' Now's a good time to update our session variables, in case we don't shut
    ' down cleanly.
    if category = "Start" or category = "Continue" then
        this.numPlaybackEvents = this.numPlaybackEvents + 1
    end if

    RegWrite("session_duration", this.sessionTimer.TotalSeconds().toStr(), "analytics")
    RegWrite("session_playback_events", this.numPlaybackEvents.toStr(), "analytics")

    this.numEvents = this.numEvents + 1

    url = this.baseUrl
    url = url + "&utms=" + this.numEvents.toStr()
    url = url + "&utmn=" + this._random(1000000000,9999999999).toStr()   'Random Request Number
    url = url + "&utmac=" + this.account
    url = url + "&utmt=event"
    url = url + "&utme=" + this._formatEvent(category, action, label, value) + this._formatCustomVars(customVars)

    print "Analytics URL: " + url
    http_get_ignore_response(url)

end function

function Analytics_startup()

    this = m 

    lastSessionDuration = RegRead("session_duration", "analytics", "0").toInt()

    if lastSessionDuration > 0 then
        lastSessionPlaybackEvents = RegRead("session_playback_events", "analytics", "0").toInt()
        this.trackEvent("Tiny Desk", "Shutdown", "", lastSessionDuration.toStr(), [invalid, invalid, { name: "NumEvents", value: lastSessionPlaybackEvents.toStr() }])
    end if

    this.trackEvent("Tiny Desk", "Startup", "", "", [])

end function

' Do final analytics processing
function Analytics_shutdown()

    this = m

    RegWrite("session_duration", this.sessionTimer.TotalSeconds().toStr(), "analytics")

end function

Function _Analytics_formatEvent(category, action, label, value) As String

    xfer = CreateObject("roUrlTransfer")

    event = "5(" + xfer.Escape(category) + "*" + xfer.Escape(action)
    if label <> invalid then
        event = event + "*" + xfer.Escape(label)
    end if
    if value <> invalid then
        event = event + ")(" + value
    end if
    event = event + ")"

    return event

End Function

Function _Analytics_formatCustomVars(vars) As String
    xfer = CreateObject("roUrlTransfer")
    vars = CreateObject("roArray", 5, false)

    if vars.count() = 0 then return ""

    names = "8"
    values = "9"
    scopes = "11"
    skipped = false

    for i = 0 to vars.Count() - 1
        if vars[i] <> invalid then
            if i = 0 then
                prefix = "("
            else if skipped then
                prefix = i.toStr() + "!"
            else
                prefix = "*"
            end if

            names = names + prefix + xfer.Escape(firstOf(vars[i].name, ""))
            values = values + prefix + xfer.Escape(firstOf(vars[i].value, ""))

            if pageVars[i] <> invalid then
                scope = "3"
            else
                scope = "2"
            end if

            scopes = scopes + prefix + scope
        else
            skipped = true
        end if
    end for

    names = names + ")"
    values = values + ")"
    scopes = scopes + ")"

    return names + values + scopes

End Function

Function _Analytics_random(num_min As Integer, num_max As Integer) As Integer

    Return (RND(0) * (num_max - num_min)) + num_min

End Function
