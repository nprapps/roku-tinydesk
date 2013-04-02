'
' Tiny Desk Roku app
'

function Main()

    globals = getGlobalAA()

    globals.analytics = Analytics()

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
    theme.backgroundColor = "#0F0F0F"

    ' Overhang
    theme.overhangSliceSD = "pkg:/images/overhang_sd.png"
    theme.overhangSliceHD = "pkg:/images/overhang_hd.png"

    ' The grid screen
    theme.gridScreenOverhangSliceSD = "pkg:/images/overhang_sd.png"
    theme.gridScreenOverhangSliceHD = "pkg:/images/overhang_hd.png"
    theme.gridScreenOverhangHeightHD = "69"
    theme.gridScreenOverhangHeightSD = "49"

    theme.gridScreenBackgroundColor = "#0F0F0F"

    ' The search screen
    theme.backgroundColor = "#000000"
    theme.buttonMenuNormalText = "#FFFFFF"
    
    app.setTheme(theme) 
    
end function
