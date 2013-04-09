'
' Video playback screen
'

' Video screen constructor 
function VideoScreen()

    ' Member vars
    this = {}
    
    ' Member functions
    this.play = VideoScreen_play
    this.close = VideoScreen_close
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

    adPlayed = false

    if globals.USE_ADS and position = 0
        this._wrapper = createObject("roImageCanvas")
        this._wrapper.show()

        adComplete = this._playAd()

        if not adComplete
            return false
        end if

        adPlayed = true
    end if

    ' MAIN VIDEO
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

    if adPlayed
        this._wrapper.close()
    end if

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

            exit while
        else if msg.isPartialResult()
            playtime = position - contentItem.playStart
            stoppedAtPct = int(position / contentItem.length * 100)

            globals.analytics.trackEvent("Tiny Desk", "Stop", contentItem.title, playtime.toStr(), [{ name: "stoppedAtPct", value: stoppedAtPct.toStr() }])

            ' If user watched more than 95% count video as watched
            if position >= int(contentItem.Length * 0.95) then
                position = 0
                savePosition(contentItem, position)

                watched = True
                globals.analytics.trackEvent("Tiny Desk", "Finish", contentItem.title, "", [])
            end if
        else if msg.isPlaybackPosition() then
            position = msg.getIndex()

            savePosition(contentItem, position)
        end if
    end while

    return watched

end function

' Show a preroll ad
function _VideoScreen_playAd()

    this = m

    timestamp = createObject("roDateTime").asSeconds()

    data = http_get_with_retry("http://pubads.g.doubleclick.net/gampad/ads?sz=400x300&iu=/6735/n6735.npr/roku&ciu_szs&impl=s&gdfp_req=1&env=vp&output=xml_vast2&unviewed_position_start=1&correlator=" + timestamp.toStr(), 1500, 0)

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

    mp4 = invalid
    bitrate = invalid

    media = vast.Ad.InLine.Creatives.Creative.Linear.MediaFiles.MediaFile

    if media.count() = 0
        print "VAST response did not contain videos."
        return true
    end if

    for each video in media
        if video@type = "video/mp4"
            mp4 = video.getText()
            bitrate = video@bitrate
            exit for
        end if
    end for

    if mp4 = invalid
        print "VAST did not contain an MP4 video url." 
        return true
    end if

    this._port = createObject("roMessagePort")
    this._canvas = createObject("roImageCanvas")
    this._player = createObject("roVideoPlayer")

    this._canvas.setMessagePort(this._port)
    this._player.setMessagePort(this._port)

    ' PREROLL AD
    this._canvas.setLayer(0, { text: "Your video will begin after this message" })
    this._canvas.show()

    adComplete = true

    this._player.setDestinationRect(this._canvas.getCanvasRect())
    this._player.addContent({
        streamQualities: ["SD"],
        streamBitrates: [bitrate],
        streamFormat: "mp4",
        streamUrls: [mp4]
    })
    this._player.play()

    while true
        msg = wait(0, this._port)

        if type(msg) = "roVideoPlayerEvent"
            if msg.isScreenClosed()
                adComplete = false
                exit while
            else if msg.isFullResult()
                exit while
            else if msg.isStatusMessage()
                if msg.getMessage() = "start of play"
                    ' Can't I just call clearLayer()?
                    this._canvas.setLayer(0, { color: "#14141400", compositionMode: "source" })
                    ' Docs say setLayer does this anyway?
                    this._canvas.show()
                end if
            end if
        else if type(msg) = "roImageCanvasEvent"
            if msg.isRemoteKeyPressed()
                index = msg.getIndex()

                ' Back or Up to exit
                if index = 0 or index = 2
                    adComplete = false
                    exit while
                end if
            end if
        end if
    end while

    this._player.stop()
    this._canvas.close()

    return adComplete

end function

' Close the video screen, used to prevent flicker
function VideoScreen_close()

    this = m

    this._screen.close()

end function
