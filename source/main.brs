sub main()
  
  message_port = CreateObject("roMessagePort")
  
  splash = CreateObject("roImageCanvas")
  splash.SetMessagePort(message_port)
  splash_message(splash, "Press the back or up button for the list of videos.                                                                                                                                Press OK if you're bored and want to skip ahead.")
  splash.Show()
  
  Sleep(1000)
  
  feed = get_feed()
  
  gogogo = true
  grid_screen = null
  next_index = find_next_unwatched(feed, 0)
     
  while true
    if gogogo
      gogogo = false
      watch_video(feed, next_index, splash) 'the 0th video has a weird lead-in?
      grid_screen = get_grid_screen(message_port, feed)
      grid_screen.Show()
    end if
    
    ' wait for an event
    msg = wait(0, message_port)
    
    if msg.isListItemSelected()
      grid_screen.Close()
      watch_video(feed, msg.GetData(), splash)
      grid_screen = get_grid_screen(message_port, feed)
      grid_screen.Show()
    end if    
    
  end while
  
end sub

' when to mark as watched? when you hit ok? when you hit next?

function watch_video(feed, feed_index, splash)
  
  message_port = splash.GetMessagePort()
	
  video_canvas = CreateObject("roImageCanvas")
  video_canvas.SetMessagePort(message_port)
  
  video_player = CreateObject("roVideoPlayer")
  video_player.SetMessagePort(message_port)
  video_player.SetDestinationRect(video_canvas.GetCanvasRect())
  video_player.SetContentList(feed)
  video_player.SetPositionNotificationPeriod(1)
  
  m.paused = false
  m.position = 0
  current_url = ""
  current_index = invalid
  
  video_player.SetNext(feed_index)
  video_player.Play()
  
  while true
    ' wait for an event
    msg = wait(0, message_port)

    if msg.isStreamStarted()
        ' once the video starts, clear out the canvas so it doesn't cover the video
        ' this baby gets run every time you seek forward, so beware
        splash_clear_background(splash)
        current_url = msg.GetInfo()["url"]
        current_index = find_index(current_url, feed)
            
    elseif msg.isPlaybackPosition()
      m.position = msg.GetIndex()
      if m.position > 2
        ' clear the splash after a few seconds
        splash_clear(splash)
      end if
    
    elseif msg.isRemoteKeyPressed()
      index = msg.GetIndex()

      if index = 0 or index = 2
        ' UP / BACK -- go to grid screen
        exit while
        
      else if index = 9
        ' >> -- seek forward
        video_player.Seek(m.position * 1000 + 60 * 1000)
        
      else if index = 4
        ' LEFT -- go to previous video in feed
        next_index = current_index - 1
        if next_index = -1
          next_index = feed.Count() - 1
        end if
        seek_to(video_player, splash, feed, next_index)

      else if index = 5
        ' RIGHT -- go to next video in feed
        next_index = current_index + 1
        if next_index = feed.Count()
          next_index = 0
        end if
        seek_to(video_player, splash, feed, next_index)

      else if index = 6
        ' OK -- go to next video in feed and mark as watched
        next_index = current_index + 1
        if next_index = feed.Count()
          next_index = 0
        end if
        mark_as_watched(feed, current_index)
        seek_to(video_player, splash, feed, next_index, "Skipped!                                                                                                                                                                                                                                                                ")      

      else if index = 13
        ' PAUSE / PLAY
        if m.paused
          video_player.Resume()
          m.paused = false
        else
          video_player.Pause()
          m.paused = true
        end if
      end if
      
    end if
        
  end while

end function

function splash_message(splash, message)
  splash.SetLayer(0, { color:"#FF000000", CompositionMode: "Source" })
  splash.SetLayer(1, { text: message, CompositionMode: "Source" })
end function

function splash_clear_background(splash)
  splash.SetLayer(0, { color: "#00000000", CompositionMode: "Source" })
end function

function splash_clear(splash)
  splash.SetLayer(0, { color: "#00000000", CompositionMode: "Source" })
  splash.SetLayer(1, { color: "#00000000", CompositionMode: "Source" })
end function

function find_index(current_url, feed)
  i = 0
  for each item in feed
    for each stream in item.streams
      if stream.url = current_url
        return i
      end if
    end for
    i = i + 1
  end for
end function

function seek_to(video_player, splash, feed, index, additional_message = "")
  message = additional_message + "Next: " + feed[index].title
  splash_message(splash, message)
  video_player.SetNext(index)
  video_player.Play()
end function

function mark_as_watched(feed, index)
  RegWrite(feed[index].title, "watched", "feedtv2")
end function

function is_watched(feed, index)
  read = RegRead(feed[index].title, "feedtv2")
  return read = "watched"
end function

function find_next_unwatched(feed, index)
  for i = index to feed.Count() - 1
    if not is_watched(feed, i)
      return i
    end if
  end for
  return -1
end function

function get_grid_screen(message_port, feed)
  grid_screen = CreateObject("roGridScreen")
  grid_screen.SetMessagePort(message_port)
  grid_screen.SetGridStyle("flat-landscape")
  unwatched = []
  watched = []
  for i = 0 to feed.Count() - 1
    if is_watched(feed, i)
      watched.Push(feed[i])
    else
      unwatched.Push(feed[i])
    end if
  end for
  titles = ["New","Previously viewed / skipped"]
  grid_screen.SetupLists(2)
  grid_screen.SetListNames(titles)
  grid_screen.SetContentList(0,unwatched)
  grid_screen.SetContentList(1,watched)
  return grid_screen
end function

function get_feed()
    json = BSJSON()
    data = ReadAsciiFile("pkg:/source/tinydesk.json") 

    return json.JsonDecode(data)
end function
