'
' The main grid/list screen
'

' Grid screen constructor
function GridScreen() as Object

    ' Member vars
    this = {}
    
    this.ALL = 0
    this.RECENT = 1
    this.SEARCH = 2

    this.MAX_AGE_FOR_RECENT_LIST = 60 * 60 * 24 * 14

    this.SEARCH_ITEM = {
        id: "search",
        title: "Search",
        description: "Search for an artist by name.",
        sdPosterUrl: "http://apps.npr.org/roku-tinydesk/magnifying_glass.png",
        hdPosterUrl: "http://apps.npr.org/roku-tinydesk/magnifying_glass.png"
    }

    this._port = createObject("roMessagePort")
    this._screen = createObject("roGridScreen")
    this._videoScreen = VideoScreen()
    this._searchScreen = SearchScreen()

    this._feed = []
    this._titles = ["All", "Recently watched", "Search"]
    this._lists = []
    this._visibleTitles = [] 
    this._visibleLists = []
    
    ' Member functions
    this.run = GridScreen_run
    this._watch = _GridScreen_watch
    this._search = _GridScreen_search
    this._initLists = _GridScreen_initLists
    this._refreshLists = _GridScreen_refreshLists

    ' Setup
    this._screen.setMessagePort(this._port)

    this._screen.setGridStyle("flat-landscape")
    this._screen.setDisplayMode("photo-fit")
    
    ' Always setup at least one list (keeps tooltips from appearing in the wrong place)
    this._screen.setupLists(1)

    this._screen.show()
    this._screen.showMessage("Retrieving...")

    this._feed = fetchFeed()
    this._initLists()

    this._screen.ClearMessage()


    return this

end function

' Run the GridScreen main loop, which functions as the app main loop
function GridScreen_run()

    this = m

    while true
        msg = wait(0, this._port)

        if msg = invalid then
            exit while
        end if

        if msg.isListItemSelected() then
            selected_list = msg.getIndex()
            selected_item = msg.getData()
            contentItem = this._visibleLists[selected_list][selected_item]

            if contentItem.id = "search" then
                this._search()
            else
                this._watch(contentItem)
            end if
        else if msg.isRemoteKeyPressed() then
            if msg.getIndex() = 10 then
                this._search()
            end if
        else if msg.isScreenClosed() then
            exit while
        end if
    end while

end function

' Watch a video selected from the grid
function _GridScreen_watch(contentItem)

    this = m

    watched = this._videoScreen.play(contentItem)
    setLastWatched(contentItem)

    if watched then
        markAsWatched(contentItem)
    end if

    ' Remove vid from recent list if it already exists
    for i = 0 to this._lists[this.RECENT].count() - 1
        if this._lists[this.RECENT][i].id = contentItem.id then
            this._lists[this.RECENT].delete(i)
            exit for
        end if
    end for
    
    ' Add vid to recent list
    this._lists[this.RECENT].unshift(contentItem)

    this._refreshLists()

    this._screen.setFocusedListItem(this.RECENT, 0)

end function

' Execute a search
function _GridScreen_search()

    this = m

    this._lists[this.SEARCH] = this._searchScreen.search(this._feed)
    this._lists[this.SEARCH].unshift(this.SEARCH_ITEM)

    ' No results
    if this._lists[this.SEARCH].count() = 1 then
        this._refreshLists()
        this._screen.setFocusedListItem(this.SEARCH, 0)
    ' One result
    else if this._lists[this.SEARCH].count() = 2 then
        contentItem = this._lists[this.SEARCH][1]
        this._watch(contentItem)
    ' Multiple results
    else
        this._refreshLists()
        this._screen.setFocusedListItem(this.SEARCH, 1)
    end if

end function

' Initialize the video lists
function _GridScreen_initLists()

    this = m

    for i = 0 to this._titles.count() - 1
        this._lists[i] = []
    end for

    now = createObject("roDateTime").asSeconds()
    threshold = now - this.MAX_AGE_FOR_RECENT_LIST 

    for each contentItem in this._feed 
        contentItem["lastWatched"] = getLastWatched(contentItem)

        if contentItem["lastWatched"] <> invalid then
            if contentItem["lastWatched"] > threshold then
                this._lists[this.RECENT].Push(contentItem)
            end if
        end if
    end for
    
    this._lists[this.ALL] = this._feed
    sortBy(this._lists[this.RECENT], "lastWatched", False)
    this._lists[this.SEARCH] = [this.SEARCH_ITEM]

    this._refreshLists()
    this._screen.setFocusedListItem(this.ALL, 0)

    this._screen.Show()

end function

' Render the grid lists, but only those with data
function _GridScreen_refreshLists()

    this = m

    this._visibleTitles = [this._titles[this.ALL]]
    this._visibleLists = [this._lists[this.ALL]]

    if this._lists[this.RECENT].Count() > 0 then
        this._visibleTitles.Push(this._titles[this.RECENT])
        this._visibleLists.Push(this._lists[this.RECENT])
    end if

    if this._lists[this.SEARCH].Count() > 0 then
        this._visibleTitles.Push(this._titles[this.SEARCH])
        this._visibleLists.Push(this._lists[this.SEARCH])
    end if

    this._screen.setupLists(this._visibleTitles.Count())
    this._screen.setListNames(this._visibleTitles)

    for i = 0 to this._visibleLists.Count() - 1
        this._screen.setContentList(i, this._visibleLists[i])
        this._screen.setFocusedListItem(i, 0)
    end for

    this._screen.Show()

end function

