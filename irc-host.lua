--Derive modem
local possibleSides = {
    "up";
    "left";
    "right";
    "down";
    "front";
    "back";
}
local Modem;
local Ports = {};
for i, Side in pairs(possibleSides) do
    Modem = peripheral.wrap(Side);
    if (Modem) then break end;
end
Modem.open(65535); --Open a private port
print("gamer 2")
--Handler for determining if a port is open
--coroutine.wrap(function()
    while (true) do
        local pingWait, senderPort, replyPort, returnedData = os.pullEvent("modem_message");
        replyPort = tonumber(replyPort);
        senderPort = tonumber(senderPort);
        print("gamer")
        local success, err = pcall(function()
            if (type(returnedData) ~= "table") then
                print("uh?");
                if (replyPort and replyPort < 65535 ) then
                    print("Not packet");
                    Modem.transmit(replyPort or senderPort, replyPort or senderPort, {
                        code = "400";
                        message = "irc-host: Data that was sent was not a packet.";
                    })
                end
            else
                print"Ports?"
                if (returnedData.type == "open_ports") then
                    print("Is ports.")
                    assert(returnedData.discriminator);
                    local openPorts = {};
                    for i = 1, 65534 do
                        if (not Ports[i]) then
                            openPorts[#openPorts+1] = i;
                        end
                    end
                    print("Transmitted.")
                    Modem.transmit(replyPort, 65535, {
                        code = "200";
                        response = {
                            discriminator = returnedData.discriminator;
                            ports = openPorts;
                        };
                    })
                end
            end
        end)
        if (not success) then
            print("bad");
            print("error");
            Modem.transmit(replyPort or senderPort, replyPort or senderPort, {
                code = "400";
                discriminator = (returnedData or {}).discriminator;
                message = "irc-host: Bad request.";
            })
        end
    end
--end)();
