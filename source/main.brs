'
' Tiny Desk Roku app
'

function Main()

    globals = getGlobalAA()

    globals.analytics = Analytics()
    globals.USE_ADS = true
    globals.TIME_BETWEEN_ADS = 60 * 60
    globals.firstPlay = true
    globals.lastAdTimestamp = 0

    reg = createObject("roRegistry")
    reg.delete("recent")

    print "Starting up"
    globals.analytics.startup()

    initTheme()
    grid = GridScreen()

    print "Running the grid"
    grid.run()

    print "Shutting down"
    globals.analytics.shutdown()

end function

' Setup the app theme
function initTheme()

    app = createObject("roAppManager")
    theme = createObject("roAssociativeArray")

    ' Overhang
    theme.overhangSliceSD = "pkg:/images/overhang_sd.png"
    theme.overhangSliceHD = "pkg:/images/overhang_hd.png"

    ' List items
    theme.gridScreenFocusBorderSD = "pkg:/images/item_highlight_sd.png"
    theme.gridScreenFocusBorderHD = "pkg:/images/item_highlight_hd.png"
    theme.gridScreenBorderOffsetSD = "(-5,-5)"
    theme.gridScreenBorderOffsetHD = "(-10,-10)"

    ' The grid screen
    theme.gridScreenOverhangSliceSD = "pkg:/images/overhang_sd.png"
    theme.gridScreenOverhangSliceHD = "pkg:/images/overhang_hd.png"
    theme.gridScreenOverhangHeightHD = "79"
    theme.gridScreenOverhangHeightSD = "49"
    theme.gridScreenDescriptionImageSD = "pkg:/images/background_description_sd.png"
    theme.gridScreenDescriptionImageHD = "pkg:/images/background_description_hd.png"
    theme.gridScreenDescriptionOffsetSD = "(80,80)"
    theme.gridScreenDescriptionOffsetHD = "(155,175)"

    theme.gridScreenBackgroundColor = "#000000"
    theme.gridScreenMessageColor = "#ebebeb"
    theme.gridScreenRetrievingColor = "#ebebeb"
    theme.gridScreenListNameColor = "#ebebeb"
    theme.gridScreenDescriptionDateColor = "#666666"
    theme.gridScreenDescriptionRuntimeColor = "#666666"

    ' The search screen
    theme.backgroundColor = "#000000"
    theme.buttonMenuNormalText = "#ebebeb"
    theme.breadcrumbTextRight = "#000000"

    app.setTheme(theme)

end function
