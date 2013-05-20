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

    this.account = "UA-5828686-51"
    this.appName = "roku-tinydesk"
    this.domain = "apps.npr.org"
    this.numEvents = 0
    this.numWatched = 0
    this.numFinished = 0
    this.baseUrl = ""
    
    this.sessionTimer = createObject("roTimespan")

    this.startup = Analytics_startup
    this.shutdown = Analytics_shutdown
    this.trackEvent = Analytics_trackEvent
    this._formatEvent = _Analytics_formatEvent
    this._formatCustomVars = _Analytics_formatCustomVars
    this._random = _Analytics_random

    xfer = createObject("roUrlTransfer")
    device = createObject("roDeviceInfo")
    screenSize = device.getDisplaySize()

    this.baseUrl = "http://www.google-analytics.com/__utm.gif"
    this.baseUrl = this.baseUrl + "?utmwv=1"
    this.baseUrl = this.baseUrl + "&utmsr=" + screenSize.w.toStr() + "x" + screenSize.h.toStr()
    this.baseUrl = this.baseUrl + "&utmsc=24-bit"
    this.baseUrl = this.baseUrl + "&utmul=" + device.getCurrentLocale()
    this.baseUrl = this.baseUrl + "&utmje=0"
    this.baseUrl = this.baseUrl + "&utmfl=-"
    this.baseUrl = this.baseUrl + "&utmdt=" + xfer.Escape(this.appName)
    this.baseUrl = this.baseUrl + "&utmp=" + xfer.Escape(this.appName)
    this.baseUrl = this.baseUrl + "&utmhn=" + xfer.Escape(this.domain)
    this.baseUrl = this.baseUrl + "&utmr=-"
    this.baseUrl = this.baseUrl + "&utmvid=" + xfer.Escape(device.getDeviceUniqueId())

    ' Initialize our "cookies"
    domainHash = "102995024"
    visitorId = RegRead("AnalyticsID", "analytics", invalid)

    if visitorId = invalid then
        visitorId = this._random(1000000000, 9999999999).toStr()
        RegWrite("AnalyticsID", visitorId, "analytics")
    end if

    timestamp = createObject("roDateTime")
    firstTimestamp = RegRead("FirstTimestamp", "analytics", invalid)
    prevTimestamp = RegRead("PrevTimestamp", "analytics", invalid)
    curTimestamp = timestamp.asSeconds().toStr()

    RegWrite("PrevTimestamp", curTimestamp, "analytics")

    if prevTimestamp = invalid then
        prevTimestamp = curTimestamp
    end if

    if firstTimestamp = invalid then
        RegWrite("FirstTimestamp", curTimestamp, "analytics")
        firstTimestamp = curTimestamp
    end if

    numSessions = RegRead("NumSessions", "analytics", "0").toint() + 1
    RegWrite("NumSessions", numSessions.toStr(), "analytics")

    this.baseUrl = this.baseUrl + "&utmcc=__utma%3D" + domainHash + "." + visitorId + "." + firstTimestamp + "." + prevTimestamp + "." + curTimestamp + "." + numSessions.toStr()
    this.baseUrl = this.baseUrl + "%3B%2B__utmb%3D" + domainHash + ".0.10." + curTimestamp + "000"
    this.baseUrl = this.baseUrl + "%3B%2B__utmc%3D" + domainHash + ".0.10." + curTimestamp + "000"

    this.sessionTimer.mark()

    return this 

end function

function Analytics_trackEvent(category, action, label, value, customVars)

    this = m

    if action = "Start" or action = "Continue" then
        this.numWatched = this.numWatched + 1
    end if

    if action = "Finish" then
        this.numFinished = this.numFinished + 1
    end if

    RegWrite("sessionDuration", this.sessionTimer.TotalSeconds().toStr(), "analytics")
    RegWrite("sessionNumWatched", this.numWatched.toStr(), "analytics")
    RegWrite("sessionNumFinished", this.numFinished.toStr(), "analytics")

    this.numEvents = this.numEvents + 1

    url = this.baseUrl
    url = url + "&utms=" + this.numEvents.toStr()
    url = url + "&utmn=" + this._random(1000000000, 9999999999).toStr()
    url = url + "&utmac=" + this.account
    url = url + "&utmt=event"
    url = url + "&utme=" + this._formatEvent(category, action, label, value) + this._formatCustomVars(customVars)

    httpGetWithRetry(url, 2000, 0)

end function

' Do initial analytics reporting
function Analytics_startup()

    this = m 
    
    device = createObject("roDeviceInfo")

    lastSessionDuration = RegRead("sessionDuration", "analytics", "0").toInt()

    if lastSessionDuration > 0 then
        lastSessionWatched = RegRead("sessionNumWatched", "analytics", "0").toInt()
        lastSessionFinished = RegRead("sessionNumFinished", "analytics", "0").toInt()
        this.trackEvent("Tiny Desk", "Shutdown", "", lastSessionDuration.toStr(), [{ name: "numWatched", value: lastSessionWatched.toStr() }, { name: "numFinished", value: lastSessionFinished.toStr() }])
    end if

    this.trackEvent("Tiny Desk", "Startup", "", "", [
        { name: "rokuModel", value: device.getModelDisplayName() },
        { name: "rokuFirmware", value: device.getVersion().mid(2, 4) }
    ])

end function

' Do final analytics reporting
function Analytics_shutdown()

    this = m

    RegWrite("session_duration", this.sessionTimer.TotalSeconds().toStr(), "analytics")

end function

' Format event for request string 
Function _Analytics_formatEvent(category, action, label, value) As String

    xfer = createObject("roUrlTransfer")

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

' Format custom variables for request string
Function _Analytics_formatCustomVars(vars) As String

    xfer = createObject("roUrlTransfer")

    if vars.count() = 0 then
        return ""
    end if

    names = "8"
    values = "9"
    scopes = "11"
    skipped = false

    for i = 0 to vars.count() - 1
        if vars[i] <> invalid then
            if i = 0 then
                prefix = "("
            else if skipped then
                prefix = i.toStr() + "!"
            else
                prefix = "*"
            end if

            names = names + prefix + xfer.Escape(vars[i].name)
            values = values + prefix + xfer.Escape(vars[i].value)

            if vars[i] <> invalid then
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

' Generate a random number suitable for analytics
Function _Analytics_random(num_min As Integer, num_max As Integer) As Integer

    Return (RND(0) * (num_max - num_min)) + num_min

End Function
