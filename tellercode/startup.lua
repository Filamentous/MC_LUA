local monitor = peripheral.wrap("top")
local databaseID = 5
local turtleID = 8
local tellerMachineID = 6

-- Basic utilities for drawing and interaction
function drawButton(x, y, text, color)
    local width = #text + 2
    paintutils.drawFilledBox(x, y, x + width, y + 1, color)
    monitor.setCursorPos(x + 1, y)
    monitor.setTextColor(colors.white)
    monitor.write(text)
end

function clearScreen()
    monitor.setBackgroundColor(colors.black)
    monitor.clear()
    monitor.setCursorPos(1, 1)
end

-- Draw the numeric keypad for card number input
function drawKeypad()
    clearScreen()
    local buttons = {"1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "Enter", "Clear"}
    local y = 2
    for i, button in ipairs(buttons) do
        drawButton(2, y, button, colors.blue)
        y = y + 2
        if i % 3 == 0 then y = y + 1 end  -- Add a space every three buttons
    end
end

-- Handling touch input for the numeric keypad
function handleKeypadInput()
    local label = {"1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "Enter", "Clear"}
    local input = ""
    while true do
        local event, side, x, y = os.pullEvent("monitor_touch")
        local value = math.floor((y - 2) / 3) * 3 + math.ceil((x - 1) / 8)
        if value >= 1 and value <= 12 then
            if label == "Enter" then
                return input
            elseif label == "Clear" then
                input = ""
                clearScreen()
                drawKeypad()
            else
                input = input .. label
                if #input == 4 then
                    return input
                end
            end
        end
    end
end

function waitForItemDepositAndSend()
    drawButton(2, 14, "Deposit Items", colors.green)
    os.pullEvent("monitor_touch")  -- Wait for touch event to confirm deposit
    rednet.send(turtleID, {command = "activate"}, "turtleCommand")
end

local itemValues = {
    ["minecraft:diamond"] = 1,
    ["minecraft:netherite_scrap"] = 4,
    ["minecraft:netherite_ingot"] = 8
}

-- Function to process received items and update the balance
function receiveItemsData()
    local senderId, items, protocol = rednet.receive("itemData")
    if protocol == "itemData" and senderId == turtleID then  -- Ensure the data is from the turtle
        local totalValue = 0
        for _, item in ipairs(items) do
            if itemValues[item.name] then
                totalValue = totalValue + (itemValues[item.name] * item.count)
            end
        end

        -- Send the calculated value as a balance update to the database
        rednet.open("back")
        rednet.send(databaseID, {type = "updateBalance", amount = totalValue}, "databaseQuery")
        rednet.close()

        -- Optionally, display the updated balance
        monitor.clear()
        monitor.setCursorPos(1, 1)
        monitor.write("Balance updated by: " .. totalValue)
        sleep(2)
        drawMainMenu()
    end
end

function main()
    rednet.open("back")
    drawKeypad()
    local cardNumber = handleKeypadInput()
    -- Here would be the logic to check/create the card number via rednet
    waitForItemDepositAndSend()
    receiveItemsData()
end

main()
