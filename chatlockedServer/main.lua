require("enet")

-- MAJOR TODO LIST:
-- keep settings after disconnecting & save them when entered for quick access on a client restart

-- disallow general chat, force pms
-- "memos" or whatever they were - the group chats Karkat kept making and fucking up

version = "0.7"

dateAndTime = os.date("%c", os.time())
dateAndTime = string.gsub(string.sub(dateAndTime, 1, 8), "/", "-").."_"..string.gsub(string.sub(dateAndTime, 10), ":", ".")
love.filesystem.newFile(dateAndTime..".txt")
love.filesystem.append(dateAndTime..".txt", "Log initialised.")

function love.load()
  local portno = 1720 -- must be same as client portno
  host = enet.host_create("*:"..portno)
  love.graphics.setNewFont("consola.ttf", 10)
  
  textlog = {}
  name1 = {}
  name2 = {}
  nameFull = {}
  nameInitials = {}
  messagenumber = {}
  colour = {}
  peerList = {}
  
  love.window.setTitle("Chatlocked Server v"..version)
end

-- executable functions
function cmd_help(peer)
  peer:send("Available commands:")
  peer:send("!help - Shows this command list.")
end

-- fix append to add newline
function dat_append(text)
  love.filesystem.append(dateAndTime..".txt", "\n"..text)
end

function love.update(dt)
  local event = host:service(100)
  if event then
	-- table.insert(textlog, "got event - "..event.type)
	if event.type == "connect" then
	  for i=1,#messagenumber do
	    if messagenumber[i] < 4 then
		  dat_append("refused a connection due to different client connecting")
		  table.insert(textlog, "refused a connection due to different client connecting")
		  event.peer:send("Connection failed, please try again soon.")
		  event.peer:send("exec disconnect")
		end
	  end
	  dat_append("connected to '"..event.peer:index().."'")
	  table.insert(textlog, "connected to '"..event.peer:index().."'")
	  messagenumber[event.peer:index()] = 1
	elseif event.type == "receive" then
	  if event.data == "ping!" then
	    event.peer:send("pong!")
		if nameFull[event.peer:index()] then
		  table.insert(textlog, "pinged by "..nameFull[event.peer:index()])
	    else
		  table.insert(textlog, "pinged by '"..event.peer:index().."'")
		end
	  elseif messagenumber[event.peer:index()] == 1 then
		name1[event.peer:index()] = event.data
		messagenumber[event.peer:index()] = 2
	  elseif messagenumber[event.peer:index()] == 2 then
		name2[event.peer:index()] = event.data
		nameFull[event.peer:index()] = name1[event.peer:index()]..string.upper(string.sub(name2[event.peer:index()], 1, 1))..string.sub(name2[event.peer:index()], 2)
		nameInitials[event.peer:index()] = string.upper(string.sub(name1[event.peer:index()], 1, 1)..string.sub(name2[event.peer:index()], 1, 1))
		messagenumber[event.peer:index()] = 3
	  elseif messagenumber[event.peer:index()] == 3 then
		colour[nameInitials[event.peer:index()]] = event.data
		peerList[event.peer:index()] = event.peer
		
		dat_append("'"..event.peer:index().."' is now known as "..nameFull[event.peer:index()])
		table.insert(textlog, "'"..event.peer:index().."' is now known as "..nameFull[event.peer:index()])
		  
		-- send all clients the new colour
		host:broadcast("Update colour database")
		host:broadcast(nameInitials[event.peer:index()])
		host:broadcast(colour[nameInitials[event.peer:index()]])
		host:broadcast("exec addpeer "..nameFull[event.peer:index()])
		 
		-- send new client everyone else's colours
		for i=0,#peerList do
		  if nameInitials[i] and not (i == event.peer:index()) then
		    event.peer:send("Update colour database")
		    event.peer:send(nameInitials[i])
		    event.peer:send(colour[nameInitials[i]])
			event.peer:send("exec addpeer "..nameFull[i])
		  end
		end
		
		host:broadcast("--------------------------------------------------")
		host:broadcast(nameInitials[event.peer:index()]..": "..nameFull[event.peer:index()].." has joined the chat.")
		host:broadcast("--------------------------------------------------")
		messagenumber[event.peer:index()] = 4
	  else
	    dat_append(nameFull[event.peer:index()]..": "..event.data)
		table.insert(textlog, nameFull[event.peer:index()]..": "..event.data)
		event.peer:send("received")
		if string.sub(event.data, 1, 1) == "!" then
		  -- client has sent a ! command
		  -- client's could send anything, so add a prefix to the sent command
		  if string.match(string.sub(event.data, 2), "%a+") then -- protect from just a !
		    local func, finderror = findfunction("cmd_"..string.lower(string.match(string.sub(event.data, 2), "%a+")))
		    if func then
		      if string.match(string.sub(event.data, 3), "%s") then -- has a space after 'exec ', therefore has argument
		        func(event.peer, string.sub(string.match(string.sub(event.data, 3), "%s%w+"), 2))
		      else
		        func(event.peer) -- no argument
		      end
		    else
		      event.peer:send("There is no command called '"..string.lower(string.match(string.sub(event.data, 2), "%a+")).."' on this server. Type !help for a list.")
		    end
		  end
		else
		  host:broadcast(nameInitials[event.peer:index()]..": "..event.data)
		end
	  end
	elseif event.type == "disconnect" then	  
	  if messagenumber[event.peer:index()] == 4 then
	    -- only broadcast a disconnect if their connection was broadcast
	    host:broadcast("--------------------------------------------------")
	    host:broadcast(nameInitials[event.peer:index()]..": "..nameFull[event.peer:index()].." has left the chat.")
		host:broadcast("--------------------------------------------------")
		dat_append("disconnected from "..nameFull[event.peer:index()].."")
	    table.insert(textlog, "disconnected from "..nameFull[event.peer:index()].."")
	  else
	    dat_append("disconnected from '"..event.peer:index().."'")
	    table.insert(textlog, "disconnected from '"..event.peer:index().."'")
	  end
      if peerList[event.peer:index()] == event.peer then
	    table.remove(peerList, event.peer:index())
		host:broadcast("exec removepeer "..nameFull[event.peer:index()])
	  end
	  
	  -- wipe client data to prevent new clients recieving this as their own
	  messagenumber[event.peer:index()] = nil
	  if name1[event.peer:index()] then name1[event.peer:index()] = nil end
	  if name2[event.peer:index()] then name2[event.peer:index()] = nil end
	  if nameFull[event.peer:index()] then nameFull[event.peer:index()] = nil end
	  if colour[nameInitials[event.peer:index()]] then colour[nameInitials[event.peer:index()]] = nil end
	  if nameInitials[event.peer:index()] then nameInitials[event.peer:index()] = nil end
	end
  else
	-- table.insert(textlog, "timeout")
  end
  
  if #textlog > (math.floor(love.window.getHeight()/16)-2) then
	table.remove(textlog, 1)
  end
end

function love.draw()
  for i=1,#textlog do
	love.graphics.print(textlog[i], 8, (i*16)-8)
  end
end

function love.quit()
  if shutdown == 0 then return true end
  
  host:broadcast("All systems shutting down...")
  host:flush()
end

-- Find a function with the given string name in the global table
function findfunction(x)
  assert(type(x) == "string")
  local f=_G
  for v in x:gmatch("[^%.]+") do
    if type(f) ~= "table" then
       return nil, "looking for '"..v.."' expected table, not "..type(f)
    end
    f=f[v]
  end
  if type(f) == "function" then
    return f
  else
    return nil, "expected function, not "..type(f)
  end
end
