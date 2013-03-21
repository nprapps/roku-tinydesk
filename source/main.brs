' nprapps Roku app

' TODO: when to mark as watched? when you hit ok? when you hit next?

' Main function
sub main()
    message_port = CreateObject("roMessagePort")
  
    splash = CreateObject("roImageCanvas")
    splash.SetMessagePort(message_port)
    splash_message(splash, "Press the back or up button for the list of videos.                                                                                                                                Press OK if you're bored and want to skip ahead.")
    splash.Show()
  
    feed = get_feed()
  
    start_now = true
    grid_screen = null
    next_index = find_next_unwatched(feed, 0)
     
    ' Main loop
    while true
        if start_now 
            start_now = false
            watch_video(feed, next_index, splash) 

            ' Go to grid
            grid_screen = get_grid_screen(message_port, feed)
            grid_screen.Show()
        end if

        ' Wait for an event
        msg = wait(0, message_port)

        ' Video selected
        if msg.isListItemSelected()
            ' Switch to video
            row = msg.GetIndex()
            selection = msg.GetData()

            grid_screen.Close()
            ' NB: WRONG, needs to take into account the row and use watched/unwatched arrays
            watch_video(feed, selection, splash)

            ' Return to grid
            grid_screen = get_grid_screen(message_port, feed)
            grid_screen.Show()
        end if    
    end while
  
end sub

' Watch a video from the feed
function watch_video(feed, feed_index, splash)
    message_port = splash.GetMessagePort()

    video_canvas = CreateObject("roImageCanvas")
    video_canvas.SetMessagePort(message_port)

    video_player = CreateObject("roVideoPlayer")
    video_player.SetMessagePort(message_port)
    video_player.SetDestinationRect(video_canvas.GetCanvasRect())
    video_player.SetContentList([feed[feed_index]])
    video_player.SetPositionNotificationPeriod(1)

    paused = false
    position = 0
    current_url = ""
    started = False

    video_player.SetNext(0)
    video_player.Play()

    while true
        ' Wait for an event
        msg = wait(0, message_port)

        if msg.isStreamStarted()
            ' once the video starts, clear out the canvas so it doesn't cover the video
            ' this baby gets run every time you seek forward, so beware
            splash_clear_background(splash)
            started = True
        else if msg.isPlaybackPosition()
            position = msg.GetIndex()
            if position > 2
                ' clear the splash after a few seconds
                splash_clear(splash)
            end if
        else if msg.isRemoteKeyPressed()
            index = msg.GetIndex()

            ' UP / BACK -- go to grid screen
            if index = 0 or index = 2
                exit while
            ' >> -- seek forward
            else if index = 9
                video_player.Seek(m.position * 1000 + 60 * 1000)
            ' LEFT -- go to previous video in feed
            else if index = 4
                next_index = feed_index - 1
                
                if next_index = -1
                    next_index = feed.Count() - 1
                end if

                feed_index = next_index
            
                seek_to(video_player, splash, feed, feed_index)
            ' RIGHT -- go to next video in feed
            else if index = 5
                next_index = feed_index + 1
                
                if next_index = feed.Count()
                    next_index = 0
                end if

                feed_index = next_index
            
                seek_to(video_player, splash, feed, feed_index)
            ' OK -- go to next video in feed and mark as watched
            else if index = 6
                next_index = feed_index + 1

                if next_index = feed.Count()
                    next_index = 0
                end if

                mark_as_watched(feed, feed_index)

                feed_index = next_index

                seek_to(video_player, splash, feed, feed_index, "Skipped!                                                                                                                                                                                                                                                                ")      
            ' PAUSE / PLAY
            else if index = 13
                if paused
                    video_player.Resume()
                    paused = false
                else
                    video_player.Pause()
                    paused = true
                end if
            end if
        end if
    end while
end function

' Display a splash message
function splash_message(splash, message)
    splash.SetLayer(0, { color:"#FF000000", CompositionMode: "Source" })
    splash.SetLayer(1, { text: message, CompositionMode: "Source" })
end function

' Clear the splash background
function splash_clear_background(splash)
    splash.SetLayer(0, { color: "#00000000", CompositionMode: "Source" })
end function

' Clear the splash completely
function splash_clear(splash)
    splash.SetLayer(0, { color: "#00000000", CompositionMode: "Source" })
    splash.SetLayer(1, { color: "#00000000", CompositionMode: "Source" })
end function

' Find the index of the feed item matching a given url
function find_index(current_url, feed)
    i = 0

    for each item in feed
        if item.Stream.Url = current_url
            return i
        end if

        i = i + 1
    end for
end function

' Jump to a certain point in the video
function seek_to(video_player, splash, feed, index, additional_message = "")
    message = additional_message + "Next: " + feed[index].Title
    splash_message(splash, message)
    video_player.SetContentList([feed[index]])
    video_player.SetNext(0)
    video_player.Play()
end function

' Mark a video watched in the registry
function mark_as_watched(feed, index)
    RegWrite(feed[index].Id, "watched", "nproku")
end function

' Check the registry to see if a feed item has been watched
function is_watched(feed, index)
    read = RegRead(feed[index].Id, "nproku")

    return read = "watched"
end function

' Find the first unwatched video in the feed
function find_next_unwatched(feed, start_index)
    for i = start_index to feed.Count() - 1
        if not is_watched(feed, i)
            return i
        end if
    end for
    
    return -1
end function

' Create the video grid from the video feed
function get_grid_screen(message_port, feed)
    grid_screen = CreateObject("roGridScreen")
    grid_screen.SetMessagePort(message_port)
    grid_screen.SetGridStyle("flat-landscape")
    
    unwatched = []
    watched = []

    for i = 0 to feed.Count() - 1
        if is_watched(feed, i)
            watched.Push(feed[i])
        else
            unwatched.Push(feed[i])
        end if
    end for

    titles = ["New","Previously viewed / skipped"]
    
    grid_screen.SetupLists(2)
    grid_screen.SetListNames(titles)
    grid_screen.SetContentList(0, unwatched)
    grid_screen.SetContentList(1, watched)
    
    return grid_screen
end function

' Parse the video feed
function get_feed()
    json = BSJSON()
    data = ReadAsciiFile("pkg:/source/tinydesk.json") 

    return json.JsonDecode(data)
end function
