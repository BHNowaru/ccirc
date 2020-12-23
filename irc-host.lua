--Derive modem
local possibleSides = {
    "front",
    "back",
    "left",
    "right",
    "top",
    "bottom"
}

local Modem;
local Ports = {};
for i, Side in pairs(possibleSides) do
    if (peripheral.getType(Side) == "modem") then
        Modem = peripheral.wrap(Side);
        if (Modem) then break end;
    end
end

if (not Modem) then error("Modem not found.") end;
Modem.open(65535); --Open a private port
--Handler for determining if a port is open

function table.find(table, value, init)
    for i, v in pairs(table) do
        if (v == value) then
            return i
        end    
    end
end
while (true) do
    local pingWait, side, senderPort, replyPort, returnedData = os.pullEvent("modem_message");
    replyPort = tonumber(replyPort);
    senderPort = tonumber(senderPort);
    local success, err = pcall(function()
        if (type(returnedData) ~= "table") then
            print(returnedData);
            if (replyPort and replyPort < 65535 ) then
                print("Not packet");
                Modem.transmit(replyPort or senderPort, replyPort or senderPort, {
                    code = "502";
                    response = {
                        discriminator = (returnedData or {}).discriminator;
                        message = "irc-host: Data that was sent was not a packet.";
                    }
                })
            end
        else
            print"Ports?"
            print(returnedData.type);
            if (returnedData.type == "open_ports") then
                print("Is ports.")
                assert(returnedData.discriminator);
                local openPorts = {};
                for i = 1, 65534 do
                    if (not table.find(Ports, i)) then
                        openPorts[#openPorts+1] = i;
                    end
                end
                print("Transmitted to", replyPort or senderPort)
                print("Discriminator:", returnedData.discriminator)
                Modem.transmit(replyPort or senderPort, replyPort or senderPort, {
                    code = "200";
                    response = {
                        discriminator = returnedData.discriminator;
                        ports = openPorts;
                    };
                })
            elseif (returnedData.type == "is_port_open") then
                local discriminator = returnedData.discriminator;
                local port = tonumber(returnedData.port) or 0000;
                print("Port:", port)        
                Modem.transmit(replyPort or senderPort, replyPort or senderPort, {
                    code = "400";
                    response = {
                        discriminator = (returnedData or {}).discriminator;
                        is_open = not not Ports[port];
                    }
                })   
            elseif (returnedData.type == "request_port_open") then
                local discriminator = returnedData.discriminator;
                local port = returnedData.port;
                print("Requested port:", port);
                if (table.find(Ports, port) or not tonumber(port)) then
                    Modem.transmit(replyPort or senderPort, replyPort or senderPort, {
                        code = "502";
                        response = {
                            discriminator = (returnedData or {}).discriminator;
                            message = "Port occupied.";
                        }
                    })
                    print('uh')
                else
                    print('uh 2', returnedData.discriminator);
                    Ports[port] = true
                    Modem.transmit(replyPort or senderPort, replyPort or senderPort, {
                        code = "400";
                        response = {
                            discriminator = (returnedData or {}).discriminator;
                            message = "Success."
                        }
                    })
                end
            end
        end
    end)
    if (not success) then
        print("bad");
        print("error");
        Modem.transmit(replyPort or senderPort, replyPort or senderPort, {
            code = "502";
            response = {
                discriminator = (returnedData or {}).discriminator;
                message = "irc-host: Bad request.";
            }
        })
        term.setTextColor(term.isColour and colours.red or colours.lightGray)
        print(err);
        term.setTextColor(colours.white);
    end
end

