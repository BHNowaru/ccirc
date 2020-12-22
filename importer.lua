local callingArguments = {...};
local names = {
    ["irc-client"] = true,
    ["irc-host"] = true,
    ["irc-server"] = true
}
if (callingArguments[1] == "-s") then-- -s for select
    callingArguments = {table.unpack(callingArguments, 2)}
    for i, v in pairs(callingArguments) do
        if (names[i:lower()]) then
            if (fs.exists("./"..i..".lua")) then
                fs.delete("./"..i..".lua");
            end
            local success = shell.run("wget", "https://raw.githubusercontent.com/BHNowaru/ccirc/main/" .. i .. ".lua", i..".lua")
            if (not success) then
                term.setTextColour(term.isColour and colours.red or colours.lightGray);
                print("Could not install", tostring(i)..".lua.")
                term.setTextColour(colours.white);
            else
                term.setTextColour(term.isColour and colours.lime or colours.white);
                print("Successfully installed!")
                term.setTextColour(colours.white);
            end
        end
    end
else
    for i, v in pairs(names) do
        if (fs.exists("./"..i..".lua")) then
            fs.delete("./"..i..".lua");
        end
        local success = shell.run("wget", "https://raw.githubusercontent.com/BHNowaru/ccirc/main/" .. i .. ".lua", i..".lua")
        if (not success) then
            term.setTextColour(term.isColour and colours.red or colours.lightGray);
            print("Could not install", tostring(i)..".lua.")
            term.setTextColour(colours.white);
        else
            term.setTextColour(term.isColour and colours.lime or colours.white);
            print("Successfully installed!")
            term.setTextColour(colours.white);
        end
    end
end
