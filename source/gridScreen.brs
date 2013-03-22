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
    m.WATCHED = 1

    m.titles = ["New", "Watched / skipped"]
    m.lists = []

    screen.SetupLists(m.titles.Count())
    screen.SetListNames(m.titles)

    screen.Show()

    screen.ShowMessage("Fetching videos...")

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

                if watched and selected_list <> m.WATCHED then
                    mark_as_watched(feedItem)
                    initLists(screen, feed)
                end if
            else if msg.isScreenClosed() then
                return -1
            end if
        end if
    end while

End Function

' Parse the video feed
function fetchFeed()

    json = BSJSON()
    data = ReadAsciiFile("pkg:/source/tinydesk.json") 

    return json.JsonDecode(data)

end function

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
    end for
   
    for i = 0 to m.lists.Count() - 1
        screen.SetContentList(i, m.lists[i])
    end for

End Function

' Mark a video watched in the registry
function mark_as_watched(feedItem)

    RegWrite(feedItem.Id + "_watched", "watched", "nproku")

end function

' Check the registry to see if a feed item has been watched
function is_watched(feedItem)

    read = RegRead(feedItem.Id + "_watched", "nproku")

    return read = "watched"

end function

