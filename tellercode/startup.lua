-- Load necessary APIs
os.loadAPI("json")

-- Define item values
local itemValues = {
    ["minecraft:diamond"] = 1,
    ["minecraft:netherite_scrap"] = 4,
    ["minecraft:netherite_ingot"] = 8
}

local monitor = peripheral.wrap("right") -- Adjust as per your setup
local databaseID = 5 -- The ID of the central database computer

-- Setup monitor display
function displayMessage(message)
    monitor.clear()
    monitor.setCursorPos(1,1)
    monitor.write(message)
end

-- Function to get player ID from user input and create a new account if necessary
function getPlayerID()
    displayMessage("Please enter your Player ID:")
    local playerID = tonumber(read())
    if not playerID then
        displayMessage("Invalid Player ID entered.")
        sleep(2)
        return
    end

    -- Ask to create new card if account does not exist
    rednet.send(databaseID, {type = "createNewCard", playerID = playerID}, "databaseQuery")
    local senderId, response, protocol = rednet.receive("databaseResponse")
    if response.success then
        displayMessage(response.response)
        sleep(2)
        return playerID
    else
        displayMessage(response.response)
        sleep(2)
        return getPlayerID()  -- Re-attempt to get a valid ID or create new card
    end
end

-- Main server loop
function main()
    rednet.open("back") -- Make sure the modem is on the correct side

    while true do
        displayMessage("Welcome to the Deposit Machine")
        local playerID = getPlayerID()
        if playerID then
            displayMessage("Please insert items and press any key when done.")
            os.pullEvent("key") -- Wait for user to confirm item deposit
            local senderId, message, protocol = rednet.receive("itemData")
            if protocol == "itemData" and message.items then
                processItems(playerID, message.items)
                sleep(5) -- Display the message for 5 seconds
            end
        end
    end
end

-- Run the main function
main()
