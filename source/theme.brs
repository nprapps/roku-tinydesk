'
' This makes it pretty
'

function SetTheme()

    app = CreateObject("roAppManager")
    theme = CreateObject("roAssociativeArray")
    
    ' The grid screen
    theme.GridScreenBackgroundColor = "#000000"

    ' The search screen
    theme.BackgroundColor = "#000000"
    theme.ButtonMenuNormalText = "#FFFFFF"
    
    app.SetTheme(theme) 
    
end function
