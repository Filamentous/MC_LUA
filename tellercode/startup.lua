local monitor = peripheral.wrap("top")
local redstone = peripheral.wrap("bottom")
local databaseID = 5  -- ID of your database computer
local turtleID = 8    -- ID of your turtle
local itemValues = {
    ["minecraft:diamond"] = 1,
    ["minecraft:netherite_scrap"] = 4,
    ["minecraft:netherite_ingot"] = 8
}

-- Utility functions for GUI
function setupMonitor()
    monitor.clear()
    monitor.setTextScale(0.5)
    monitor.setBackgroundColor(colors.black)
end

function drawButton(x, y, width, height, text, bgColor)
    paintutils.drawFilledBox(x, y, x + width - 1, y + height - 1, bgColor)
    monitor.setCursorPos(x + 2, y + (height / 2))
    monitor.setTextColor(colors.white)
    monitor.write(text)
end

-- GUI screens
function drawMainMenu()
    setupMonitor()
    drawButton(2, 4, 30, 3, "New Card", colors.green)
    drawButton(2, 9, 30, 3, "Enter Card Number", colors.green)
    drawButton(2, 14, 30, 3, "Deposit Items", colors.green)
end

function drawPinPad()
    setupMonitor()
    local keys = {"1", "2", "3", "4", "5", "6", "7", "8", "9", "Clear", "0", "Enter"}
    local yPos = 4
    for i, key in ipairs(keys) do
        local xPos = 2 + ((i-1) % 3) * 10
        if key == "Enter" then
            drawButton(xPos, yPos, 8, 3, key, colors.lime)  -- Make Enter key lime green for visibility
        else
            drawButton(xPos, yPos, 8, 3, key, colors.green)  -- Other keys are regular green
        end
        if i % 3 == 0 then yPos = yPos + 4 end
    end
end

function handlePinPadInput()
    local pin = ""
    while true do
        local event, side, x, y = os.pullEvent("monitor_touch")
        local row = math.floor((y - 3) / 4)
        local col = math.floor((x - 1) / 10)
        local index = row * 3 + col + 1
        if index > 9 then index = index + 3 end -- Adjust for bottom row buttons
        local keys = {"1", "2", "3", "4", "5", "6", "7", "8", "9", "", "0", "Clear", "Enter"}
        local key = keys[index]
        -- Check if the key press was on a button
        if key == "Clear" then
            pin = "" -- Reset pin
            monitor.setCursorPos(5, 19)
            monitor.clearLine()
        elseif key == "Enter" then
            if #pin == 4 then  -- Ensure pin is exactly 4 digits before accepting
                return pin -- Return pin if Enter is pressed
            end
        elseif key ~= "" and key ~= nil then
            pin = pin .. key
            monitor.setCursorPos(5, 19)
            monitor.clearLine()
            monitor.write(pin)
        end
        if #pin == 4 then
            return pin
        end
    end
end


-- Touch event handling
function handleTouchEvents()
    while true do
        local event, side, x, y = os.pullEvent("monitor_touch")
        if y >= 4 and y <= 6 then
            return "new_card"
        elseif y >= 9 and y <= 11 then
            return "enter_card"
        elseif y >= 14 and y <= 16 then
            return "deposit_items"
        end
    end
end

-- Actions for each menu item
function createNewCard()
    drawPinPad()
    local cardNum = handlePinPadInput()
    monitor.write("pin: ", cardNum)
    rednet.open("back")
    rednet.send(databaseID, {type = "createNewCard", cardNumber = cardNum}, "databaseQuery")
    local senderId, response = rednet.receive("databaseResponse")
    monitor.clear()
    if response.success then
        monitor.setCursorPos(1, 1)
        monitor.write("Card " .. cardNum .. " created successfully!")
        redstone.setOutput("bottom", true)
        sleep(1)
        redstone.setOutput("bottom", false)
    else
        monitor.setCursorPos(1, 1)
        monitor.write("Failed to create card: " .. response.message)
    end
    sleep(2)
    drawMainMenu()
    rednet.close()
end

function enterCardNumber()
    monitor.clear()
    drawPinPad()
    local cardNum = handlePinPadInput()
    rednet.open("back")
    rednet.send(databaseID, {type = "checkCard", cardNumber = cardNum}, "databaseQuery")
    local senderId, response = rednet.receive("databaseResponse")
    monitor.clear()
    if response.exists then
        monitor.setCursorPos(1, 1)
        monitor.write("Card number exists. You may deposit items.")
    else
        monitor.setCursorPos(1, 1)
        monitor.write("Card number does not exist. Try again.")
        sleep(2)
        drawMainMenu()
        return
    end
    sleep(2)
    drawMainMenu()
    rednet.close()
end

function startDepositProcess()
    rednet.open("back")
    monitor.clear()
    monitor.setCursorPos(1, 1)
    monitor.write("Enter your card number:")
    drawPinPad()
    local cardNum = handlePinPadInput()
    monitor.write("Entered pin:", cardNum)

    -- Check if the card exists in the database
    rednet.send(databaseID, {type = "checkCard", cardNumber = cardNum}, "databaseQuery")
    local senderId, response = rednet.receive("databaseResponse")
    if not response.exists then
        monitor.write("Card number does not exist. Please try again.")
        sleep(2)
        drawMainMenu()
        return
    end

    -- Confirm deposit
    monitor.clear()
    monitor.setCursorPos(1, 1)
    monitor.write("Confirm items deposit?")
    drawButton(2, 4, 30, 3, "Confirm", colors.green)
    
    while true do
        local event, side, x, y = os.pullEvent("monitor_touch")
        if x >= 2 and x <= 32 and y >= 4 and y <= 7 then
            break -- Exit loop if confirm button is pressed
        end
    end

    -- Send command to turtle to collect items
    rednet.send(turtleID, {command = "activate"}, "turtleCommand")
    monitor.clear()
    monitor.setCursorPos(1, 1)
    monitor.write("Waiting for items to be deposited...")

    -- Receive item data from turtle
    local senderId, items, protocol = rednet.receive("itemData")
    if protocol == "itemData" and senderId == turtleID then
        -- Calculate the total value of items
        local totalValue = 0
        for _, item in ipairs(items) do
            if itemValues[item.name] then
                totalValue = totalValue + (itemValues[item.name] * item.count)
            end
        end
        
        -- Update balance in the database
        rednet.send(databaseID, {type = "updateBalance", amount = totalValue, playerID = cardNum}, "databaseQuery")
        monitor.setCursorPos(1, 2)
        monitor.write("Items processed and balance updated.")
        sleep(2)
    end
    drawMainMenu()
    rednet.close()
end


-- Main function
function main()
    drawMainMenu()
    while true do
        local action = handleTouchEvents()
        if action == "new_card" then
            createNewCard()
        elseif action == "enter_card" then
            enterCardNumber()
        elseif action == "deposit_items" then
            startDepositProcess()
        end
    end
end

main()
