local possibleSides = {
    "front",
    "back",
    "left",
    "right",
    "top",
    "bottom"
}


local Modem;
local recommendedPort;
for i, Side in pairs(possibleSides) do
    if (peripheral.getType(Side) == "modem") then
        Modem = peripheral.wrap(Side);
        if (Modem) then break end;
    end
end

if (not Modem) then
    error("Modem is not installed. Please install one. An ender modem is most preferred.");
end
math.randomseed(os.time())
local discriminator = (os.clock());
print("What port is your server on?");
local Port = tonumber(io.read())
if (not Port) then error("Port is invalid.") end;
local hasRequestedForPortOpen = false;
Modem.open(65535);
while true do
    if (not hasRequestedForPortOpen) then
        Modem.transmit(65535, 65535, {
            type = "is_port_open";
            discriminator = discriminator;
            port = Port;
        })
        hasRequestedForPortOpen = true;
        print("transmitted!");
    end
    local Event, side,  senderPort, replyPort, portData, uh = os.pullEvent("modem_message");
    local code = portData.code;
    isOpen = portData.response.is_open;
    print(isOpen);
    if (not isOpen) then
        print("Invalid port--port is not open.");
        return;
    else
        break;
    end
end
Modem.close(65535);
Modem.open(Port);
local isColour = term.isColour();
if (isColour) then
    term.setTextColor(colours.lime);
else
    term.setTextColor(colours.lightGrey);
end
print("Success! Connected to the server.");
term.setTextColour(colours.white)

print("What is your username?")
local Username = io.read();

function string.split(self, delimiter)
    local result = { }
    local from  = 1
    local delim_from, delim_to = string.find( self, delimiter, from  )
    while delim_from do
        table.insert( result, string.sub( self, from , delim_from-1 ) )
        from  = delim_to + 1
        delim_from, delim_to = string.find( self, delimiter, from  )
    end
    table.insert( result, string.sub( self, from  ) )
    return result
end

Modem.transmit(Port, Port, {
    type = "connect";
    request = {
        discriminator = discriminator;
        username = Username;
        iscolor = isColour;
    }
})

--message receiving handler
local MESSAGES_MAX = 8 --8 messages at max
local cachedMessages = {};
function messageReceivingHandler()
    while true do
        local Event, Side, senderPort, replyPort, portData, _ = os.pullEvent("modem_message");
        -- print("WE R GAMING");
        if (portData and portData.type == "message") then
            --message format: 
            --[[
                BHNoire (admin)
                Today ・ 12:00 AM
            ]]--
            -- print'handling!'
            -- local messageData = portData.response;
            cachedMessages[MESSAGES_MAX] = nil;
            table.insert(cachedMessages, 1, portData.response)
            term.setCursorPos(1,1)
            term.clear();
            for Index =  MESSAGES_MAX, 1, -1 do
                local messageData = cachedMessages[Index]
                if (messageData) then
                    local user = messageData.user;
                    local tag = user.tag;
                    local message = messageData.message;
                    local usercolor = user.color;

                    term.setTextColour(usercolor);
                    print(tag)
                    term.setTextColor(colours.white);
                    print("Day "..os.day().. " | " ..os.time())
                    if (message:lower():match("@"..Username:lower())) then
                        if (isColour) then
                            term.setTextColour(colours.yellow);
                        end
                    elseif(message:lower():sub(1,1) == "/") then
                        args = message:lower():sub(2):split(" ");
                        local command = table.remove(args, 1);
                        for i, v in pairs(colours) do
                            if (isColour and i:lower() == command) then
                                term.setTextColor(v);
                                break;
                            end
                        end
                        message = table.concat(args);
                    end
                    print(message);
                    term.setTextColour(colours.white);
                    print("-------\n")
                end
            end
        end
    end
end

--message sending handler

function messageSendingHandler()
    while true do
        -- print("Sending!");
        local Message = io.read()
        if (Message and #Message > 0) then
            Modem.transmit(Port, Port, {
                type = "message_send";
                request = {
                    discriminator = discriminator;
                    username = Username;
                    message = Message;
                }
            })
        end
    end
end

local pingsMissed = 0; -- if 5 pings are missed, then close the modem and end the script.

function ping()
    while true do
        if (pingsMissed >= 5) then
            error("5 pings were missed. Exiting script...");
            return;
        end
        os.sleep(6); --ping every 5 seconds, +1 to compensate for delay 
        Modem.transmit(Port, Port, {
            type = "ping";
            request = {
                discriminator = discriminator;
            }
        })
        local ponged = false;
        parallel.waitForAny(
            function()
                while not ponged do
                    local Event, Side, senderPort, replyPort, pongData, _ = os.pullEvent("modem_message");
                    if (pongData.type == "pong" and pongData.response.discriminator == discriminator) then
                        ponged = true;
                        pingsMissed = 0;
                        return ponged;
                    end
                    sleep(0.5)
                end
            end, 
            function()
                sleep(1); --wait 1 second
                if (not ponged) then
                    pingsMissed = pingsMissed + 1;
                end
            end
        )
    end
end

function onTermination()
    while true do
        local eventstatus = os.pullEventRaw("terminate");
        print("event:", eventstatus)
        if (eventstatus == "terminate") then
            Modem.transmit(Port, Port, {
                type = "disconnect";
                request = {
                    discriminator = discriminator;
                }
            })
            Modem.close(Port);
            print("Disconnected succesfully.")
            return true;
        end
    end
end

function i_am_alive()
    while true do
        local Event, Side, senderPort, replyPort, pongData, _ = os.pullEvent("modem_message");
        if (pongData.type == "active" and pongData.response and pongData.response.discriminator == discriminator) then
            -- print("Got ping! Ponging...")
            Modem.transmit(Port, Port, {
                type = "imalive";
                response = {
                    discriminator = discriminator;
                }
            })
        end
    end
end

function disconnect()
    while true do
        local Event, Side, senderPort, replyPort, pongData, _ = os.pullEvent("modem_message");
        if (pongData.type == "disconnect" and pongData.response and pongData.response.discriminator == discriminator) then
            printError("Disconnected.");
            print("Reason:", pongData.response.reason or "None.")
            return;
        end
    end
end

parallel.waitForAny(messageReceivingHandler, messageSendingHandler, ping, onTermination, i_am_alive);
