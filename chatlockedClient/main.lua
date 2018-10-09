require("enet")

-- debug global var
DEBUG = false

version = "0.7b"

textlog = {}
textcolor = {}

trueload = true
intromsg = 0
name1 = ""
name2 = ""
ourcolor = "none"

maxLength = 10

local icon = love.image.newImageData("icon.png")
love.window.setIcon( icon )
love.graphics.setBackgroundColor(238,238,238)
love.graphics.setNewFont("cour.ttf", 12)

dateAndTime = os.date("%c", os.time())
dateAndTime = string.gsub(string.sub(dateAndTime, 1, 8), "/", "-").."_"..string.gsub(string.sub(dateAndTime, 10), ":", ".")
love.filesystem.newFile(dateAndTime..".txt")
love.filesystem.append(dateAndTime..".txt", "Log initialised.")

function love.load()
  ipaddress = "localhost"
  portno = 1720 -- must be same as server portno
  host = enet.host_create()
  
  finish = false
  connected = false
  curText = ""
  updatingColourDatabase = 0
  memoryForColour = ""
  toutcnt = 0
  peerList = {}
  
  if trueload then
    table.insert(textlog, "Please type the first half of your username (all lowercase - 10 characters max).")
  else
    table.insert(textlog, "Type an IP address to connect to.")
  end
  trueload = false
  love.window.setTitle("Chatlocked Client v"..version)
end

-- fix append to add newline
function betterappend(file, text)
  love.filesystem.append(file, "\n"..text)
end

-- executable functions
function clearscreen()
  textlog = {}
end

function maxtextlength(length)
  -- limits characters in a post
  maxLength = tonumber(length)
end

function addpeer(peername)
  table.insert(peerList, peername)
end

function removepeer(peername)
  for i=1,#peerList do
    if peerList[i] == peername then
	  table.remove(peerList, i)
	end
  end
end

function disconnect()
  if server then
    server:disconnect()
	server = nil
  end
  if host then
    host:flush()
	host = nil
  end
  love.load()
  intromsg = 3
end

-- code
function love.update(dt)
  if finish then return end
  if not server then return end
  
  local timeout = 50
  if not connected then timeout = 2500 end
  local event = host:service(timeout)
  if event then
    toutcnt = 0
	sentping = false
    -- print("got event - "..event.type)
	connected = true
	if event.type == "connect" then
	  betterappend(dateAndTime..".txt", "Connected to "..ipaddress..".")
      table.insert(textlog, "Connected to "..ipaddress..".")
	  server:send(name1)
	  server:send(name2)
	  server:send(ourcolor)
	elseif event.type == "receive" then
	  if event.data == "received" or event.data == "pong!" then
	    -- do nothing, but protect from adding to chat
	  elseif string.sub(event.data, 1, 4) == "exec" then
	    -- server has requested that we execute a client-side command
		local func, finderror = findfunction(string.match(string.sub(event.data, 6), "%a+"))
		if func then
		  if string.match(string.sub(event.data, 6), "%s") then -- has a space after 'exec ', therefore has argument
		    func(string.sub(string.match(string.sub(event.data, 6), "%s%w+"), 2))
		  else
		    func() -- no argument
		  end
		end
	  elseif event.data == "All systems shutting down..." then
	    betterappend(dateAndTime..".txt", event.data)
	    table.insert(textlog, event.data)
	    server:disconnect()
        host:flush()
		server = nil
	    host = nil
        love.load()
		intromsg = 3
	  elseif event.data == "Update colour database" then
	    updatingColourDatabase = 1
	  elseif updatingColourDatabase == 1 then
	    nameInitials = event.data
	    updatingColourDatabase = 2
	  elseif updatingColourDatabase == 2 then
	    textcolor[nameInitials] = event.data
	    updatingColourDatabase = 0
	  else
	    betterappend(dateAndTime..".txt", event.data)
	    table.insert(textlog, event.data)
	  end
	end
  else
    if not connected then
	  betterappend(dateAndTime..".txt", "Failed to connect to "..ipaddress..".")
	  table.insert(textlog, "Failed to connect to "..ipaddress..".")
	  server:disconnect()
	  host:flush()
	  server = nil
	  host = nil
	  love.load()
	  intromsg = 3
	else -- add one to the timeout counter
	  toutcnt = toutcnt + 1
	  if toutcnt >= 150 and not sentping then
	    server:send("ping!")
		sentping = true
	  elseif toutcnt >= 300 then
	    sentping = false
	    clearscreen()
		betterappend(dateAndTime..".txt", "Lost connection to server on "..ipaddress..".")
	    table.insert(textlog, "Lost connection to server on "..ipaddress..".")
	    server:disconnect()
	    host:flush()
	    server = nil
	    host = nil
	    love.load()
		intromsg = 3
	  end
	end
	-- table.insert(textlog, "timeout")
  end
  
  if #textlog > (math.floor(love.window.getHeight()/16)-3) then
    table.remove(textlog, 1)
  end
end

function love.draw()
  for i=1,#textlog do
    setRGBfromname(getcolornamefromtext(textlog[i]))
    love.graphics.print(textlog[i], 8, (i*16)-8)
  end
  setRGBfromname(ourcolor)
  love.graphics.print(curText, 8, (math.floor(love.window.getHeight()/16)-1)*16)
  
  setRGBfromname("none")
  love.graphics.rectangle("fill", love.window.getWidth()-200, 0, 1, love.window.getHeight())
  
  setRGBfromname(ourcolor)
  if peerList[1] then love.graphics.print(peerList[1].." (you)", love.window.getWidth()-192, 0) end
  for i=2,#peerList do
    if peerList[i] then
      setRGBfromname(getcolornamefromtext(string.upper(string.sub(peerList[i], 1, 1))..string.match(peerList[i], "%u")))
	  love.graphics.print(peerList[i], love.window.getWidth()-192, 16*(i-1))
	end
  end
  setRGBfromname("none")
  if DEBUG then love.graphics.print("toutcnt: "..toutcnt, love.window.getWidth()-192, love.window.getHeight()-16) end
end

function getcolornamefromtext(strIn)
  if textcolor[string.sub(strIn, 1, 2)] then
    return textcolor[string.sub(strIn, 1, 2)]
  else
    return "none"
  end
end

function setRGBfromname(strIn)
  if strIn == "none" then love.graphics.setColor(10/255,10/255,10/255)
  elseif strIn == "blue" then love.graphics.setColor(7/255,21/255,205/255)
  elseif strIn == "pink" then love.graphics.setColor(181/255,54/255,218/255)
  elseif strIn == "red" then love.graphics.setColor(224/255,7/255,7/255)
  elseif strIn == "light green" then love.graphics.setColor(74/255,201/255,37/255)
  elseif strIn == "gray" then love.graphics.setColor(98/255,98/255,98/255)
  elseif strIn == "yellow" then love.graphics.setColor(161/255,161/255,0/255)
  elseif strIn == "turquoise" then love.graphics.setColor(0/255,130/255,130/255)
  elseif strIn == "dark red" then love.graphics.setColor(161/255,0/255,0/255)
  elseif strIn == "orange" then love.graphics.setColor(161/255,80/255,0/255)
  elseif strIn == "dark green" then love.graphics.setColor(65/255,102/255,0/255)
  elseif strIn == "dark blue" then love.graphics.setColor(0/255,0/255,86/255)
  elseif strIn == "light blue" then love.graphics.setColor(0/255,86/255,130/255)
  elseif strIn == "dark purple" then love.graphics.setColor(43/255,0/255,87/255)
  elseif strIn == "dark green" then love.graphics.setColor(0/255,129/255,65/255)
  elseif strIn == "dark pink" then love.graphics.setColor(119/255,0/255,60/255)
  elseif strIn == "purple" then love.graphics.setColor(106/255,0/255,106/255)
  elseif strIn == "cyan" then love.graphics.setColor(0/255,213/255,242/255)
  elseif strIn == "light pink" then love.graphics.setColor(255/255,111/255,242/255)
  elseif strIn == "light orange" then love.graphics.setColor(242/255,164/255,0/255)
  elseif strIn == "green" then love.graphics.setColor(31/255,148/255,0/255)
  elseif strIn == "light gray" then love.graphics.setColor(146/255,146/255,146/255)
  elseif strIn == "dark gray" then love.graphics.setColor(50/255,50/255,50/255)
  end
end

function love.textinput(t)
  if string.len(curText) >= maxLength then
    -- cant type no more
  else
    curText = curText..t
  end
end

function CheckIP(address)
  if address == "localhost" then return true end
  if string.find(address, "%d+%.%d+%.%d+%.%d+") then
    return true
  else
    return false
  end
end

function love.keypressed(k)
  if k == "return" then
    if not server then
	  if intromsg == 0 then
	    if string.len(curText) > 1 then
	      name1 = string.lower(curText)
		  table.insert(textlog, "Please type the second half of your username (all lowercase - 10 characters max).")
		  intromsg = 1
		else
		  table.insert(textlog, "Names must be at least 2 letters.")
		end
	  elseif intromsg == 1 then
	    if string.len(curText) > 1 then
	      name2 = string.lower(curText)
	      maxtextlength(12) -- "exec maxtextlength 8"
		  table.insert(textlog, "Choose a colour.")
		  intromsg = 2
		else
		  table.insert(textlog, "Names must be at least 2 letters.")
		end
	  elseif intromsg == 2 then
	    if not checkColorName(string.lower(curText)) then
		  table.insert(textlog, "Can't find a color with the name "..string.sub(string.upper(curText), 1, 1)..string.sub(string.lower(curText), 2)..".")
		  table.insert(textlog, "Try a more common color name, or check colors.txt for a full list.")
		else
		  table.insert(textlog, "Your identity has been setup.")
		  table.insert(textlog, "Type an IP address to connect to.")
		  maxtextlength(15)
		  ourcolor = curText
		  intromsg = 3
		end
	  elseif intromsg == 3 then
	    if curText == "" then curText = ipaddress end
	    ipaddress = curText
	    if CheckIP(ipaddress) then
		  intromsg = 4
		  maxtextlength(75)
		  clearscreen()
	      server = host:connect(ipaddress..":"..portno)
	    else
	      betterappend(dateAndTime..".txt", ipaddress.." is not a valid IP address.")
	      table.insert(textlog, ipaddress.." is not a valid IP address.")
		  maxtextlength(15)
		  curText = ""
	    end
	  end
	else
      server:send(curText)
	end
	curText = ""
  elseif k == "backspace" then
    curText = string.sub(curText, 1, string.len(curText)-1)
  elseif k == "escape" then
    betterappend(dateAndTime..".txt", "Disconnected.")
	table.insert(textlog, "Disconnected.")
    if intromsg > 3 then disconnect() end
  end
end

function love.quit()
  if not server then return end
  clearscreen()
  server:disconnect()
  host:flush()
end

colornames = {"blue","pink","red","light green","gray","yellow","turquoise","dark red","orange","dark green","dark blue","light blue","dark purple","dark green","dark pink","purple","cyan","light pink","light orange","green","light gray","dark gray"}
function checkColorName(nametocheck)
  for _, value in pairs(colornames) do
    if value == nametocheck then
      return true
    end
  end
  return false
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
