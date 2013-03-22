' Setup the grid screen
Function preShowGridScreen() As Object

    port = CreateObject("roMessagePort")
    screen = CreateObject("roGridScreen")
    screen.SetMessagePort(port)

    return screen

End Function

' Run the grid screen
Function showGridScreen(screen as Object) as Integer

    m.UNWATCHED = 0
    m.WATCHED = 1

    m.titles = ["New", "Watched / skipped"]
    m.lists = []
    m.lists[m.UNWATCHED] = []
    m.lists[m.WATCHED] = []

    screen.SetupLists(m.titles.Count())
    screen.SetListNames(m.titles)

    screen.Show()

    screen.ShowMessage("Fetching videos...")

    feed = fetchFeed()
    initLists(feed)

    for i = 0 to m.titles.Count() - 1
        screen.SetContentList(i, m.lists[i])
    end for

    screen.ClearMessage()

    ' TODO: if there is an unwatched video, play it immediately

    while true
        msg = wait(0, screen.GetMessagePort())

        if type(msg) = "roGridScreenEvent" then
            print "showGridScreen | msg = "; msg.GetMessage() " | index = "; msg.GetIndex()

            if msg.isListItemSelected() then
                selected_list = msg.GetIndex()
                selected_item = msg.GetData()

                showVideoScreen(m.lists[selected_list][selected_item])
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
Function initLists(feed)

    for i = 0 to feed.Count() - 1
        if is_watched(feed, i)
            m.lists[m.WATCHED].Push(feed[i])
        else
            m.lists[m.UNWATCHED].Push(feed[i])
        end if
    end for

End Function

