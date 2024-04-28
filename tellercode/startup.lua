local monitor = peripheral.wrap("top")
local databaseID = 5 -- The ID of your database computer
local turtleID = 8 -- The ID of your turtle

-- Basic utilities for drawing and interaction
function drawButton(x, y, width, height, text, color)
    paintutils.drawFilledBox(x, y, x + width - 1, y + height - 1, color)
    monitor.setCursorPos(x + (width - #text) // 2, y + height // 2)
    monitor.setTextColor(colors.white)
    monitor.write(text)
end

function clearScreen()
    monitor.setBackgroundColor(colors.black)
    monitor.clear()
    monitor.setCursorPos(1, 1)
end

-- Main menu GUI
function drawMainMenu()
    clearScreen()
    drawButton(2, 2, 38, 5, "New Card", colors.green)
    drawButton(2, 7, 38, 5, "Enter Card Number", colors.green)
    drawButton(2, 12, 38, 5, "Deposit Items", colors.blue)
end

-- Function to handle touch interactions
function handleTouchEvents()
    while true do
        local event, side, x, y = os.pullEvent("monitor_touch")
        if y >= 2 and y <= 5 then
            return "new_card"
        elseif y >= 7 and y <= 10 then
            return "enter_card"
        elseif y >= 12 and y <= 15 then
            return "deposit_items"
        end
    end
end

-- Activate turtle to collect and send item data
function activateTurtle()
    rednet.open("back")
    rednet.send(turtleID, {command = "activate"}, "turtleCommand")
    rednet.close()
end

-- Function to receive item data from turtle and update database
function receiveItemsData()
    local senderId, message, protocol = rednet.receive("itemData")
    if protocol == "itemData" and senderId == turtleID then
        -- Process received item data and update database
        local totalValue = 0
        for _, item in ipairs(message) do
            if itemValues[item.name] then
                totalValue = totalValue + (itemValues[item.name] * item.count)
            end
        end

        rednet.open("back")
        rednet.send(databaseID, {type = "updateBalance", amount = totalValue}, "databaseQuery")
        rednet.close()
    end
end

-- Main function to run the teller machine
function main()
    drawMainMenu()
    while true do
        local action = handleTouchEvents()
        if action == "new_card" then
            -- Implement new card creation logic
        elseif action == "enter_card" then
            -- Implement card number entry logic
        elseif action == "deposit_items" then
            -- Wait for user to deposit items and press the button
            activateTurtle()
            receiveItemsData()
        end
    end
end

main()  -- Start the program
