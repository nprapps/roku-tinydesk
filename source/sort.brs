'
' Generic sort algorithms.
'

' Sort a list (insertion sort)
function sort(list, ascending=True)

    for i = 1 to list.count() - 1
        value = list[i]
        j = i - 1

        while j >= 0
            if (ascending and list[j] < value) or (not ascending and list[j] > value) then 
                exit while
            end if

            list[j + 1] = list[j]
            j = j - 1
        end while

        list[j + 1] = value
    next

    return list

end function

' Sort a list of objects by some common property (bubble sort)
function sortBy(list, property, ascending=True) 

    swapped = true

    while swapped = true
        swapped = false

        for i = 0 to list.Count() - 1
            if list[i + 1] = invalid then
                exit for
            end if
            
            if (ascending and list[i][property] > list[i + 1][property]) or (not ascending and list[i][property] < list[i + 1][property]) then
                temp = list[i]
                list[i] = list[i + 1]
                list[i + 1] = temp
                swapped = true
            end if
        end for
    end while

    return list

end function

' Why the heck doesn't this work?
function sortBy_NEW(list, property, ascending=True)

    for i = 1 to list.count() - 1
        value = list[i][property]
        j = i - 1

        while j >= 0 and list[j][property] > value
            list[j + 1] = list[j]
            j = j - 1
        end while

        list[j + 1] = value
    next

    return list

end function

