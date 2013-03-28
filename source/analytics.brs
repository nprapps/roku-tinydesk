' Analytics module based on code from the Plex Roku client
' Original code: https://github.com/plexinc/roku-client-public/blob/master/Plex/source/Analytics.brs
' License to use explicitly granted: https://github.com/plexinc/roku-client-public/issues/233#issuecomment-15557688
' The Plex code was itself based on: http://bloggingwordpress.com/2012/04/google-analytics-for-roku-developers/
' Original licenses follows: 

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

Function initAnalytics()

    obj = CreateObject("roAssociativeArray")

    m.Account = "UA-5828686-4"
    m.NumEvents = 0
    m.NumPlaybackEvents = 0

    xfer = CreateObject("roUrlTransfer")

    m.BaseUrl = "http://www.google-analytics.com/__utm.gif"
    m.BaseUrl = m.BaseUrl + "?utmwv=1"
    'm.BaseUrl = m.BaseUrl + "&utmsr=" + xfer.Escape(GetGlobal("DisplayMode") + " " + GetGlobal("DisplayType"))
    m.BaseUrl = m.BaseUrl + "&utmsc=24-bit"
    m.BaseUrl = m.BaseUrl + "&utmul=en-us"
    m.BaseUrl = m.BaseUrl + "&utmje=0"
    m.BaseUrl = m.BaseUrl + "&utmfl=-"
    m.BaseUrl = m.BaseUrl + "&utmdt=tinydesk"
    m.BaseUrl = m.BaseUrl + "&utmp=tinydesk"
    m.BaseUrl = m.BaseUrl + "&utmhn=apps.npr.org"
    m.BaseUrl = m.BaseUrl + "&utmr=-"
    'm.BaseUrl = m.BaseUrl + "&utmvid=" + xfer.Escape(GetGlobal("rokuUniqueID"))

    ' Initialize our "cookies"
    domainHash = "1024141829" ' should be set by Google, but hardcode to something
    visitorID = RegRead("AnalyticsID", "analytics", invalid)

    if visitorID = invalid then
        visitorID = GARandNumber(1000000000,9999999999).ToStr()
        RegWrite("AnalyticsID", visitorID, "analytics")
    end if

    timestamp = CreateObject("roDateTime")
    firstTimestamp = RegRead("FirstTimestamp", "analytics", invalid)
    prevTimestamp = RegRead("PrevTimestamp", "analytics", invalid)
    curTimestamp = timestamp.asSeconds().ToStr()

    RegWrite("PrevTimestamp", curTimestamp, "analytics")

    if prevTimestamp = invalid then prevTimestamp = curTimestamp
    if firstTimestamp = invalid then
        RegWrite("FirstTimestamp", curTimestamp, "analytics")
        firstTimestamp = curTimestamp
    end if

    numSessions = RegRead("NumSessions", "analytics", "0").toint() + 1
    RegWrite("NumSessions", numSessions.ToStr(), "analytics")

    m.BaseUrl = m.BaseUrl + "&utmcc=__utma%3D" + domainHash + "." + visitorID + "." + firstTimestamp + "." + prevTimestamp + "." + curTimestamp + "." + numSessions.ToStr()
    m.BaseUrl = m.BaseUrl + "%3B%2B__utmb%3D" + domainHash + ".0.10." + curTimestamp + "000"
    m.BaseUrl = m.BaseUrl + "%3B%2B__utmc%3D" + domainHash + ".0.10." + curTimestamp + "000"

    m.SessionTimer = CreateObject("roTimespan")
    m.SessionTimer.mark()

    return obj

End Function

Sub analyticsTrackEvent(category, action, label, value, customVars)

    ' Now's a good time to update our session variables, in case we don't shut
    ' down cleanly.
    if category = "Playback" then m.NumPlaybackEvents = m.NumPlaybackEvents + 1
    RegWrite("session_duration", m.SessionTimer.TotalSeconds().ToStr(), "analytics")
    RegWrite("session_playback_events", m.NumPlaybackEvents.ToStr(), "analytics")

    m.NumEvents = m.NumEvents + 1

    request = CreateObject("roUrlTransfer")
    request.EnableEncodings(true)
    context = CreateObject("roAssociativeArray")
    context.requestType = "analytics"

    url = m.BaseUrl
    url = url + "&utms=" + m.NumEvents.ToStr()
    url = url + "&utmn=" + GARandNumber(1000000000,9999999999).ToStr()   'Random Request Number
    url = url + "&utmac=" + m.Account
    url = url + "&utmt=event"
    url = url + "&utme=" + analyticsFormatEvent(category, action, label, value) + analyticsFormatCustomVars(customVars)

    print "Final analytics URL: " + url
    request.SetUrl(url)
    request.AsyncGetToString()

End Sub

Sub analyticsOnStartup()

    lastSessionDuration = RegRead("session_duration", "analytics", "0").toint()

    if lastSessionDuration > 0 then
        lastSessionPlaybackEvents = RegRead("session_playback_events", "analytics", "0")
        analyticsTrackEvent("App", "Shutdown", "", lastSessionDuration.ToStr(), [invalid, invalid, { name: "NumEvents", value: lastSessionPlaybackEvents.ToStr() }])
    end if

    analyticsTrackEvent("App", "Start", "", "1", [])

End Sub

Sub analyticsCleanup()

    ' Just note the session duration. We wrote the number of playback events the
    ' last time we got one, and we won't send the actual event until the next
    ' startup.
    RegWrite("session_duration", m.SessionTimer.TotalSeconds().ToStr(), "analytics")
    m.SessionTimer = invalid

End Sub

Function analyticsFormatEvent(category, action, label, value) As String

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

Function analyticsFormatCustomVars(vars) As String
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
                prefix = i.ToStr() + "!"
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

Function GARandNumber(num_min As Integer, num_max As Integer) As Integer

    Return (RND(0) * (num_max - num_min)) + num_min

End Function
