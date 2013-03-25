' Setup the grid screen
Function preShowGridScreen() As Object

    port = CreateObject("roMessagePort")
    screen = CreateObject("roGridScreen")
    screen.SetMessagePort(port)

    screen.SetGridStyle("flat-landscape")
    screen.SetDisplayMode("photo-fit")

    return screen

End Function

' Run the grid screen
Function showGridScreen(screen as Object) as Integer

    m.UNWATCHED = 0
    m.RECENT = 1
    m.WATCHED = 2

    m.titles = ["New", "Recent", "Watched"]
    m.lists = []

    screen.SetupLists(m.titles.Count())
    screen.SetListNames(m.titles)

    screen.Show()

    screen.ShowMessage("Retrieving...")

    feed = fetchFeed()
    initLists(screen, feed)

    screen.ClearMessage()

    ' TODO: if there is an unwatched video, play it immediately

    while true
        msg = wait(0, screen.GetMessagePort())

        if type(msg) = "roGridScreenEvent" then
            print "showGridScreen | msg = "; msg.GetMessage() " | index = "; msg.GetIndex()

            if msg.isListItemSelected() then
                selected_list = msg.GetIndex()
                selected_item = msg.GetData()
                feedItem = m.lists[selected_list][selected_item]

                watched = showVideoScreen(feedItem)
                set_last_watched(feedItem)

                if watched and selected_list <> m.WATCHED then
                    mark_as_watched(feedItem)
                end if
                    
                initLists(screen, feed)
            else if msg.isScreenClosed() then
                return -1
            end if
        end if
    end while

End Function

' Parse the video feed
function fetchFeed()

    http = NewHttp("http://apps.npr.org/nproku/feed.json")
    feed = http.GetToStringWithRetry()

    return ParseJSON(feed)

end function

' BubbleSort the feed by last watched
Function sortLastWatched(feed)

    swapped = true

    while swapped = true
        swapped = false

        for i = 0 to feed.Count() - 1
            if feed[i + 1] = invalid then
                exit for
            end if

            if feed[i].lastWatched < feed[i + 1].lastWatched then
                temp = feed[i]
                feed[i] = feed[i + 1]
                feed[i + 1] = temp
                swapped = true
            end if
        end for
    end while

    return feed

End Function

' Initialize the video lists
Function initLists(screen, feed)

    for i = 0 to m.titles.Count() - 1
        m.lists[i] = []
    end for

    for each feedItem in feed
        if is_watched(feedItem)
            m.lists[m.WATCHED].Push(feedItem)
        else
            m.lists[m.UNWATCHED].Push(feedItem)
        end if

        feedItem.lastWatched = get_last_watched(feedItem)

        if feedItem.lastWatched <> invalid then
            m.lists[m.RECENT].Push(feedItem)
        end if

    end for

    m.lists[m.RECENT] = sortLastWatched(m.lists[m.RECENT])
   
    for i = 0 to m.lists.Count() - 1
        screen.SetContentList(i, m.lists[i])
    end for

End Function

' Set last watch timestamp in the registry
function set_last_watched(feedItem)

    now = CreateObject("roDateTime").asSeconds().toStr()
    RegWrite(feedItem.Id + "_recent", now, "nproku")

end function

' Get the timestamp the  video was last watched
function get_last_watched(feedItem)

    lastWatched = RegRead(feedItem.Id + "_recent", "nproku")
    
    if lastWatched = invalid
        return invalid
    end if
    
    return lastWatched.toInt()
end function

' Mark a video watched in the registry
function mark_as_watched(feedItem)

    RegWrite(feedItem.Id + "_watched", "watched", "nproku")

end function

' Check the registry to see if a feed item has been watched
function is_watched(feedItem)

    read = RegRead(feedItem.Id + "_watched", "nproku")

    return read = "watched"

end function

