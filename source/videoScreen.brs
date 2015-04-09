'
' Video playback screen
'

' Video screen constructor
function VideoScreen()

    ' Member vars
    this = {}

    ' Member functions
    this.play = VideoScreen_play
    this._playAd = _VideoScreen_playAd

    return this

end function

' Play a video and return if it was completely watched
function VideoScreen_play(contentItem, fromList="", searchTerm="") as Boolean

    this = m
    globals = getGlobalAA()

    watched = false
    position = loadPosition(contentItem)
    contentItem.playStart = position

    duration = contentItem.length

    ' Prevent events being recorded again after resume
    reachedFirstQuartile = (position > duration * 0.25)
    reachedMidpoint = (position > duration * 0.5)
    reachedThirdQuartile = (position > duration * 0.75)

    timestamp = createObject("roDateTime").asSeconds()

    adPlayed = false

    if globals.FORCE_ADS:
        goto playAd
    end if

    if globals.USE_ADS = false:
        goto skipAd
    end if

    if position <> 0:
        goto skipAd
    end if

    if globals.firstPlay = true:
        goto skipAd
    end if

    if timestamp - globals.lastAdTimestamp < globals.TIME_BETWEEN_ADS:
        goto skipAd
    end if

    playAd:

    adComplete = this._playAd()

    if not adComplete
        return false
    end if

    adPlayed = true

    globals.lastAdTimestamp = timestamp

    skipAd:

    ' Users get to skip one ad for free
    globals.firstPlay = false

    if position > 0 then
        globals.analytics.trackEvent("Tiny Desk", "Continue", contentItem.Title, "", [{ name: "fromList", value: fromList }, { name: "searchTerm", value: searchTerm }])
    else
        globals.analytics.trackEvent("Tiny Desk", "Start", contentItem.Title, "", [{ name: "fromList", value: fromList }, { name: "searchTerm", value: searchTerm }])
    end if

    print "Video playback will begin at: " position

    this._port = createObject("roMessagePort")
    this._screen = createObject("roVideoScreen")
    this._screen.setMessagePort(this._port)

    this._screen.setPositionNotificationPeriod(1)
    this._screen.setContent(contentItem)
    this._screen.show()

    while true
        msg = wait(0, this._port)

        if msg.isScreenClosed()
            exit while
        else if msg.isRequestFailed()
            ' TODO
            print "Video request failure: "; msg.getIndex(); " " msg.getData()
        else if msg.isFullResult()
            position = 0
            savePosition(contentItem, position)

            watched = True
            playtime = position - contentItem.playStart

            globals.analytics.trackEvent("Tiny Desk", "Stop", contentItem.title, playtime.toStr(), [{ name: "stoppedAtPct", value: "100" }])
            globals.analytics.trackEvent("Tiny Desk", "Finish", contentItem.title, "", [])
            globals.analytics.trackEvent("Tiny Desk", "Completion", "100", "", [])

            exit while
        else if msg.isPartialResult()
            playtime = position - contentItem.playStart

            if contentItem.length <> 0 then
                stoppedAtPct = int(position / contentItem.length * 100).toStr()
            else
                stoppedAtPct = "N/A"
            end if

            globals.analytics.trackEvent("Tiny Desk", "Stop", contentItem.title, playtime.toStr(), [{ name: "stoppedAtPct", value: stoppedAtPct }])

            ' If user watched more than 95% count video as watched
            if contentItem.length <> 0 and position >= int(contentItem.length * 0.95) then
                position = 0
                savePosition(contentItem, position)

                watched = True
                globals.analytics.trackEvent("Tiny Desk", "Finish", contentItem.title, "", [])
                globals.analytics.trackEvent("Tiny Desk", "Completion", "100", "", [])
            end if
        else if msg.isPlaybackPosition() then
            position = msg.getIndex()

            savePosition(contentItem, position)

            if position > duration * 0.25 and reachedFirstQuartile = false then
                globals.analytics.trackEvent("Tiny Desk", "Completion", "25", "", [])

                reachedFirstQuartile = true
            end if

            if position > duration * 0.5 and reachedMidpoint = false then
                globals.analytics.trackEvent("Tiny Desk", "Completion", "50", "", [])

                reachedMidpoint = true
            end if

            if position > duration * 0.75 and reachedThirdQuartile = false then
                globals.analytics.trackEvent("Tiny Desk", "Completion", "75", "", [])

                reachedThirdQuartile = true
            end if
        end if
    end while

    this._screen.close()

    return watched

end function

' Show a preroll ad
function _VideoScreen_playAd()

    this = m

    timestamp = createObject("roDateTime").asSeconds()

    data = httpGetWithRetry("http://pubads.g.doubleclick.net/gampad/ads?sz=400x300&iu=/6735/n6735.nprtest/roku&ciu_szs&impl=s&gdfp_req=1&env=vp&output=xml_vast2&unviewed_position_start=1&correlator=" + timestamp.toStr(), 2000, 0)

    if data = ""
        print "VAST response was empty or request failed."
        return true
    end if

    vast = createObject("roXmlElement")
    vast.parse(data)

    if vast.Ad.count() = 0
        print "VAST response did not contain an ad."
        return true
    end if

    videos = []

    media = vast.Ad.InLine.Creatives.Creative.Linear.MediaFiles.MediaFile

    if media.count() = 0
        print "VAST response did not contain videos."
        return true
    end if

    streamQualities = []
    streamBitrates = []
    streamUrls = []

    for each video in media
        if video@type = "video/mp4"
            mp4 = video.getText()
            height = (video@height).toInt()
            bitrate = (video@bitrate).toInt()

            if height >= 720:
                streamQualities.push("HD")
            else:
                streamQualities.push("SD")
            end if

            streamBitrates.push(bitrate)
            streamUrls.push(mp4)
        end if
    end for

    if mp4 = invalid
        print "VAST did not contain an MP4 video url."
        return true
    end if

    impression_url = vast.Ad.Inline.Impression.getText()

    eventUrls = createObject("roAssociativeArray")

    events = vast.Ad.Inline.Creatives.Creative.Linear.TrackingEvents.Tracking
    duration = vast.Ad.Inline.Creatives.Creative.Linear.Duration.getText()
    bits = duration.tokenize(":")
    duration = (bits[0].toInt() * 60 * 60) + (bits[1].toInt() * 60) + bits[2].toInt()

    reachedFirstQuartile = false
    reachedMidpoint = false
    reachedThirdQuartile = false

    for each event in events
        name = event@event

        if eventUrls.DoesExist(name) = false then
            eventUrls[name] = []
        end if

        eventUrls[name].push(event.getText())
    end for

    this._port = createObject("roMessagePort")
    this._canvas = createObject("roImageCanvas")
    this._player = createObject("roVideoPlayer")

    this._canvas.setMessagePort(this._port)
    this._player.setMessagePort(this._port)

    this._canvas.setLayer(0, { text: "Retrieving..." })
    this._canvas.show()

    adComplete = true

    this._player.setPositionNotificationPeriod(1)
    this._player.setDestinationRect(this._canvas.getCanvasRect())
    this._player.addContent({
        streamQualities: streamQualities,
        streamBitrates: streamBitrates,
        streamFormat: "mp4",
        streamUrls: streamUrls
    })
    this._player.play()
    paused = false

    while true
        msg = wait(0, this._port)

        if msg.isScreenClosed()
            adComplete = false
            exit while
        else if msg.isFullResult()
            for each url in eventUrls["complete"]
                httpGetWithRetry(url, 2000, 0)
            end for

           exit while
        else if msg.isStreamStarted()
            ' Can't I just call clearLayer()?
            this._canvas.setLayer(0, { color: "#14141400", compositionMode: "source" })
            ' Docs say setLayer does this anyway?
            this._canvas.show()

            httpGetWithRetry(impression_url, 2000, 0)

            for each url in eventUrls["start"]
                httpGetWithRetry(url, 2000, 0)
            end for

        else if msg.isRemoteKeyPressed()
            index = msg.getIndex()

            ' Back or Up to exit
            if index = 0 or index = 2
                adComplete = false
                exit while
            else if index = 13
                if paused
                    this._player.resume()
                else
                    this._player.pause()
                end if
            end if
        else if msg.isPaused()
            paused = true

            for each url in eventUrls["pause"]
                httpGetWithRetry(url, 2000, 0)
            end for
        else if msg.isResumed()
            paused = false

            for each url in eventUrls["resume"]
                httpGetWithRetry(url, 2000, 0)
            end for
        else if msg.isPlaybackPosition() then
            position = msg.getIndex()

            if position > duration * 0.25 and reachedFirstQuartile = false then
                for each url in eventUrls["firstQuartile"]
                    httpGetWithRetry(url, 2000, 0)
                end for

                reachedFirstQuartile = true
            end if

            if position > duration * 0.5 and reachedMidpoint = false then
                for each url in eventUrls["midpoint"]
                    httpGetWithRetry(url, 2000, 0)
                end for

                reachedMidpoint = true
            end if

            if position > duration * 0.75 and reachedThirdQuartile = false then
                for each url in eventUrls["thirdQuartile"]
                    httpGetWithRetry(url, 2000, 0)
                end for

                reachedThirdQuartile = true
            end if
        end if
    end while

    this._player.stop()
    this._canvas.close()

    return adComplete

end function
