'
' Utility functions for working with the registry
'

' Read a key from the registry
Function RegRead(key, section=invalid, default=invalid)

    if section = invalid then
        section = "Default"
    end if

    sec = CreateObject("roRegistrySection", section)

    if sec.Exists(key) then
        return sec.Read(key)
    end if

    return default

End Function

' Write a key to the registry
Function RegWrite(key, val, section=invalid)

    if section = invalid then
        section = "Default"
    end if

    sec = CreateObject("roRegistrySection", section)
    sec.Write(key, val)
    sec.Flush()

End Function

' Delete a key from the registry
Function RegDelete(key, section=invalid)

    if section = invalid then
        section = "Default"
    end if

    sec = CreateObject("roRegistrySection", section)
    sec.Delete(key)
    sec.Flush()

End Function

