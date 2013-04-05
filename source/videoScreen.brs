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
function VideoScreen_play(contentItem) as Boolean

    this = m
    globals = getGlobalAA()

    if globals.USE_ADS
        this._wrapper = createObject("roImageCanvas")
        this._wrapper.show()

        adComplete = this._playAd()

        if not adComplete
            return false
        end if
    end if

    ' MAIN VIDEO
    watched = false
    position = loadPosition(contentItem)
    contentItem.playStart = position

    if position > 0 then
        globals.analytics.trackEvent("Tiny Desk", "Continue", contentItem.Title, "", [])
    else
        globals.analytics.trackEvent("Tiny Desk", "Start", contentItem.Title, "", [])
    end if

    print "Video playback will begin at: " position 

    this._port = createObject("roMessagePort")
    this._screen = createObject("roVideoScreen")
    this._screen.setMessagePort(this._port)

    this._screen.setPositionNotificationPeriod(1)
    this._screen.setContent(contentItem)
    this._screen.show()

    if globals.USE_ADS
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

            globals.analytics.trackEvent("Tiny Desk", "Stop", contentItem.title, playtime.toStr(), [])
            globals.analytics.trackEvent("Tiny Desk", "Finish", contentItem.title, "", [])

            exit while
        else if msg.isPartialResult()
            playtime = position - contentItem.playStart
            globals.analytics.trackEvent("Tiny Desk", "Stop", contentItem.title, playtime.toStr(), [])

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
        streamBitrates: [195],
        streamFormat: "mp4",
        streamUrls: ["http://techslides.com/demos/sample-videos/small.mp4"],
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
