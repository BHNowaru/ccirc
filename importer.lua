local callingArguments = {...};
local names = {
    "irc-client",
    "irc-host",
    "irc-server"
}
if (callingArguments[1] == "-s") then-- -s for select
    callingArguments = {table.unpack(callingArguments, 2)}
    for i, v in pairs(callingArguments) do
        if (table.find(names, tostring(v):lower())) then
            local success = pcall(function()
                shell.run("wget", "https://raw.githubusercontent.com/BHNowaru/ccirc/main/" .. v .. ".lua", v..".lua")
            end)
            if (not success) then
                term.setTextColour(term.isColour and colours.lime or colours.white);
                print("Could not install", tostring(v)..".lua.")
                term.setTextColour(colours.white);
            else
                term.setTextColour(term.isColour and colours.red or colours.lightGray);
                print("Successfully installed")
                term.setTextColour(colours.white);
            end
        end
    end
end
