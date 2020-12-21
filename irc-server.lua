
--Determine which side the modem is on
local possibleSides = {
    "up";
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
math.randomseed(os.time())

--Instead of using a random number we can convert day + progress in day to ticks and use that instead
local discriminator = (os.clock());
local function getTimeSincePing()
    local progress_day_ticks = (os.time() * 1000 + 18000)%24000
    local total_day_ticks = os.day() * 24000 + progress_day_ticks;

    return total_day_ticks;
end

Modem.transmit(65535, 65535, {
    type = "open_ports";
    discriminator = discriminator;
    time = getTimeSincePing();
})
local openPorts = {};
while (true) do
    --eventName, senderPort, replyPort, returnedData
    local Event, senderPort, replyPort, portData = os.pullEvent("modem_message");
    if (portData.discriminator == discriminator) then
        print(portData);
    else
        print("Discriminator:", portData.discriminator);
    end
end

print("What port should the port")