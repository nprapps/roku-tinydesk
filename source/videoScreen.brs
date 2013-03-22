' Play a video
Function showVideoScreen(feedItem As Object)

    port = CreateObject("roMessagePort")
    screen = CreateObject("roVideoScreen")
    screen.SetMessagePort(port)

    screen.Show()
    screen.SetPositionNotificationPeriod(1)

    screen.SetContent(feedItem)
    screen.Show()

    while true
        msg = wait(0, port)

        if type(msg) = "roVideoScreenEvent" then
            print "showVideoScreen | msg = "; msg.getMessage() " | index = "; msg.GetIndex()

            if msg.isScreenClosed()
                exit while
            elseif msg.isRequestFailed()
                ' TODO
                print "Video request failure: "; msg.GetIndex(); " " msg.GetData()
            elseif msg.isStatusMessage()
                ' TODO
                print "Video status: "; msg.GetIndex(); " " msg.GetData()
            elseif msg.isButtonPressed()
                print "Button pressed: "; msg.GetIndex(); " " msg.GetData()
            elseif msg.isPlaybackPosition() then
                nowpos = msg.GetIndex()
                'RegWrite(episode.id, nowpos.toStr())
            end if
        end if
    end while

End Function
