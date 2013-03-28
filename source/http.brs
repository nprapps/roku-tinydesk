'
' Utility functions for making web requests
'

' Create a URL transfer object
Function create_transfer(port, url)

    xfer = CreateObject("roUrlTransfer")
    xfer.SetPort(port)
    xfer.SetUrl(url)
    xfer.EnableEncodings(true)

    return xfer

End Function

' Request a URL with automated retries
Function http_get_with_retry(url, timeout=1500, retries=5) as String

    port = CreateObject("roMessagePort")
    xfer = create_transfer(port, url)

    response = ""

    while retries > 0
        if xfer.AsyncGetToString() then
            event = wait(timeout, port)

            if type(event) = "roUrlEvent"
                response = event.GetString()
                exit while        
            elseif event = invalid
                xfer.AsyncCancel()
                
                ' Create a new transfer
                xfer = create_transfer(port, url)

                ' Backoff
                timeout = 2 * timeout
            endif
        endif

        retries = retries - 1
    end while
    
    return response 

End Function

' Fetch a URL but ignore the reply
Function http_get_ignore_response(url)

    port = CreateObject("roMessagePort")
    xfer = create_transfer(port, url)
    xfer.GetToString()

End Function
