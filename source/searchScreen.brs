'
' The video search screen.
'

' Search screen constructor
function SearchScreen() as Object

    ' Member vars
    this = {}
    
    ' Member functions
    this.search = SearchScreen_search
    this.getMatches = SearchScreen_getMatches
    this.getQuery = SearchScreen_getQuery
    this.close = SearchScreen_close
    this._getSuggestions = _SearchScreen_getSuggestions

    return this

end function

' Execute a search
function SearchScreen_search(feed)

    this = m
    globals = getGlobalAA()

    this._feed = feed
    this._query = invalid

    this._port = createObject("roMessagePort")
    this._screen = createObject("roSearchScreen")

    this._screen.setMessagePort(this._port) 
    this._screen.setBreadcrumbText("", "")
    this._screen.setSearchTermHeaderText("Suggestions:")
    this._screen.setSearchButtonText("search")
    this._screen.setClearButtonEnabled(false)
    
    this._screen.show() 

    while true 
        msg = wait(0, this._port) 

        if type(msg) = "roSearchScreenEvent"
            if msg.isScreenClosed()
                exit while
            else if msg.isCleared()
                history.Clear()
            else if msg.isPartialResult()
                this._query = msg.GetMessage()

                if len(this._query) = 0 then
                    dialog = createObject("roOneLineDialog")
                    dialog.setTitle("No results found.")
                    dialog.show()
                    sleep(2500)
                    dialog.close()
                else
                    this._screen.SetSearchTerms(this._getSuggestions())
                end if
            else if msg.isFullResult()
                this._query = msg.GetMessage()

                if len(this._query) = 0 then
                    dialog = createObject("roOneLineDialog")
                    dialog.setTitle("No results found.")
                    dialog.show()
                    sleep(2500)
                    dialog.close()
                else
                    globals.analytics.trackEvent("Tiny Desk", "Search", this._query, "", [])
                
                    exit while
                end if
            endif
        endif
    endwhile 

    'this._screen.close()

end function

' Get a list of suggestions for a given search string
function _SearchScreen_getSuggestions()

    this = m

    lQuery = lCase(this._query)
    suggestions = []

    for each contentItem in this._feed
        if instr(lCase(contentItem.searchTitle), lQuery) > 0 then
            suggestions.Push(contentItem)
        end if
    end for

    sortBy(suggestions, "sortTitle")

    return pluck(suggestions, "searchTitle")

end function

' Get a list of matches for a given search string
function SearchScreen_getMatches()

    this = m

    if this._query = invalid or this._query = "" then
        return []
    end if

    lQuery = lCase(this._query)

    matches = []

    for each contentItem in this._feed
        if instr(lCase(contentItem.searchTitle), lQuery) > 0 then
            matches.Push(contentItem)
        end if
    end for

    sortBy(matches, "sortTitle")

    return matches

end function

' Get the query last searched
function SearchScreen_getQuery()

    this = m

    return this._query

end function

' Close the screen
function SearchScreen_close()

    this = m

    this._screen.close()

end function
