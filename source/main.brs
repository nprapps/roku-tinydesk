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
    
    ' General
    theme.backgroundColor = "#141414"

    ' Overhang
    theme.overhangSliceSD = "pkg:/images/overhang_sd.png"
    theme.overhangSliceHD = "pkg:/images/overhang_hd.png"

    ' The grid screen
    theme.gridScreenOverhangSliceSD = "pkg:/images/overhang_sd.png"
    theme.gridScreenOverhangSliceHD = "pkg:/images/overhang_hd.png"
    theme.gridScreenOverhangHeightHD = "69"
    theme.gridScreenOverhangHeightSD = "49"

    theme.gridScreenBackgroundColor = "#141414"
    theme.gridScreenMessageColor = "#ebebeb"
    theme.gridScreenRetrievingColor = "#ebebeb"
    theme.gridScreenListNameColor = "#ebebeb"

    ' The search screen
    theme.backgroundColor = "#141414"
    theme.buttonMenuNormalText = "#ebebeb"
    
    app.setTheme(theme) 
    
end function
