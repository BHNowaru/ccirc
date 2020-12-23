
--Determine which side the modem is on
local possibleSides = {
    "up";
    "top";
    "left";
    "right";
    "down";
    "front";
    "back";
}
local Modem;
local recommendedPort;
for i, Side in pairs(possibleSides) do
    Modem = peripheral.wrap(Side);
    if (Modem) then break end;
end

if (not Modem) then
    error("Modem is not installed. Please install one. An ender modem is most preferred.");
end
--Instead of using a random number we can convert day + progress in day to ticks and use that instead
local discriminator = (os.clock());
local function getTimeSincePing()
    local progress_day_ticks = (os.time() * 1000 + 18000)%24000
    local total_day_ticks = os.day() * 24000 + progress_day_ticks;

    return total_day_ticks;
end

local transmitted = false;
local openPorts = {};
Modem.open(65535);
while (true) do
    --eventName, senderPort, replyPort, returnedData
    if (not transmitted) then
        Modem.transmit(65535, 65535, {
            type = "open_ports";
            discriminator = discriminator;
            time = getTimeSincePing();
        })
        transmitted = true;
        print("transmitted!");
    end
    local Event, side,  senderPort, replyPort, portData, uh = os.pullEvent("modem_message");
    print'waaa?'
    portData = portData.response;
    for i, v in pairs(portData) do
        print(i,v)
    end
    if (portData.discriminator == discriminator) then
        openPorts = portData.ports;
        break;
    else
        print("Discriminator:", portData.code);
    end
end
if (not openPorts or #openPorts <= 0) then
    print("There are not enough ports open on this server.");
    return;
end

print("What port should the server be hosted on?");
print("Recommended/Minimum port:", openPorts[1]);
local port = tonumber(io.read())
if (not port or port < openPorts[1]) then
    error("Invalid port entered. Exiting...")
end
local alreadyOpenedPort = false;

while (true) do
    if (not alreadyOpenedPort) then
        Modem.transmit(65535, 65535, {
            type = "request_port_open";
            discriminator = discriminator;
            port = port;
        });
        alreadyOpenedPort = true;
    end
    local Event, side,  senderPort, replyPort, portData, uh = os.pullEvent("modem_message");
    local code = portData.code;
    portData = portData.response;
    print'got it'
    for i, v in pairs(portData) do
        print(i,v)
    end
    if (portData.discriminator == discriminator) then
        print(discriminator)
        if (code ~= "400") then
            print("Error code:", code..".");
            print("Response:", portData.response.message)
            return
        end
        break;
    end
end

Modem.close(65535);
print("Port opened!");
Modem.open(port)
--expected data format
--[[

Data = {
    type = [message, get_online, connect, disconnect];
    request = {
        Username = ...
        Discriminator = number (id, should be used for pings);
        Message = ...
    }
    
}
]]--
local connectedUsers = {}
local function searchForUserTag(tag)
    print("Looking for tag", tag.."...")
    for i ,v in pairs(connectedUsers) do
        if (v.tag == tag) then
            return true
        end
    end
    return false;
end
function handler()
    while true do
        local Event, Side, senderPort, replyPort, portData, _ = os.pullEvent("modem_message");
        print("type:", portData.type, portData.type == "ping")
        if (portData.type and (portData.request or portData.response)) then
            print'being handled'
            if (portData.type == "message_send") then
                local request = portData.request;
                for i, v in pairs(request) do
                    print(tostring(i)..":", v)
                end
                print("--------------")
                local sendingUser = connectedUsers[request.discriminator];
                if (not sendingUser or not portData.request.message) then
                    Modem.transmit(replyPort or senderPort, replyPort or senderPort, {
                        code = "502";
                        response = {
                            message = "Not logged in.";
                        }
                    })
                end
                
                --send to other clients
                --should be like:
                --[[

                    Data = {
                        Username = ...
                        Message = ...
                    }

                ]]--
                print("Getting ready to send...")
                Modem.transmit(replyPort or senderPort, replyPort or senderPort, {
                    type = "message";
                    response = {

                        user = {
                            username = sendingUser.username;
                            tag = sendingUser.tag;
                            discriminator = portData.discriminator;
                            color = sendingUser.color or sendingUser.bwcolor
                        };
                        message = portData.request.message;
                    }
                })
            elseif (portData.type == "connect") then
                --expected data for connect:
                --[[
                    Data = {
                        type = "connect";
                        discriminator = number
                        username = ...
                        iscolor = true | false
                    }
                ]]--
                
                --[[
                    created data for connect

                    discriminator = random(1, 9999);
                    id = number;
                    username = string;
                    color = somecolor;
                    colorblindcolor = someothercolor;
                ]]
                portData = portData.request;
                local Username, Discriminator, IsColor = portData.username, portData.discriminator, portData.iscolor;
                local ID;
                repeat
                    ID = {math.random(1, 9), math.random(1, 9), math.random(1, 9), math.random(1, 9)};
                    ID = tostring(ID[1]..ID[2]..ID[3]..ID[4]);
                until not searchForUserTag(Username.."#"..ID)
                local BWColours = {
                    colours.lightGray;
                    colours.white;
                    colours.grey;
                    colors.white;
                }
                local totalColours = {};
                for i, color in pairs(colours) do
                    if (color ~= colours.black and tonumber(color)) then
                        totalColours[#totalColours+1] = color
                    end 
                end
                connectedUsers[Discriminator] = {
                    discriminator = ID;
                    id = Discriminator;
                    tag = Username.."#"..ID;
                    username = Username;
                    color = IsColor and totalColours[math.random(1, #totalColours)];
                    bwcolor = BWColours[math.random(1, #BWColours)];
                }
                local cn = connectedUsers[Discriminator];
                print("discrim:", cn.discriminator)
                print("id:", cn.id)
                print("tag:", cn.tag)
                print("un:", cn.username)
                print("color:", cn.color)
                print("bwcolor:", cn.bwcolor)

                Modem.transmit(replyPort or senderPort, replyPort or senderPort, {
                    code = "400";
                    response = {
                        discriminator = Discriminator;
                    };
                });
                print("Connected successfully!")
            elseif (portData.type == "disconnect") then
                local discrim = portData.request.discriminator; 
                print'disconnectin'
                for i, v in pairs(connectedUsers) do
                    if (v.id == discrim) then
                        connectedUsers[i] = nil;
                        break;
                    end 
                end
            elseif (portData.type == "ping") then
                print("Got the ping!", discriminator)
                Modem.transmit(replyPort or senderPort, replyPort or senderPort, {
                    type = "pong";
                    code = "400";
                    response = {
                        discriminator = portData.request.discriminator;
                    };
                });
            end
        else
            print'bad request'
            Modem.transmit(replyPort or senderPort, replyPort or senderPort, {
                code = "502";
                response = {
                    message = "Bad request.";
                }
            })
        end
    end
end;
function ping()
    while true do
        sleep(3)
        for i, v in pairs(connectedUsers) do
            sleep(0.25)
            local Discrim = tonumber(i);
            print("Discrim:", Discrim)
            local pong = false;
            parallel.waitForAny(
                function()
                    --timeout
                    sleep(5)
                    if (not pong) then
                        --Try to broadcast to them that they should leave
                        --Remove their trace from connectedUsers
                        Modem.transmit(port, port, {
                            type = "disconnect";
                            response = {
                                reason = "Did not send ping back.";
                                discriminator = Discrim;
                            }
                        })
                    end
                    return true
                end,
                function()
                    print("Pinging", v.tag)
                    Modem.transmit(port, port, {
                        type = "active";
                        response = {
                            discriminator = Discrim;
                        }
                    })
                    while true do
                        local Event, Side, senderPort, replyPort, portData, _ = os.pullEvent("modem_message");
                        if (portData.type == "imalive" and portData.response.discriminator == Discrim) then
                            pong = true
                            print(v.tag, "has ponged!")
                            return true;
                        end
                    end
                end
            )
        end
    end
end
parallel.waitForAll(handler, ping)
