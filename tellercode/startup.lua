local monitor = peripheral.wrap("top")
local databaseID = 5
local turtleID = 8
local itemValues = {
    ["minecraft:diamond"] = 1,
    ["minecraft:netherite_scrap"] = 4,
    ["minecraft:netherite_ingot"] = 8
}


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
            drawButton(xPos, yPos, 8, 3, key, colors.lime)
        else
            drawButton(xPos, yPos, 8, 3, key, colors.green)
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
        if index > 9 then index = index + 3 end
        local keys = {"1", "2", "3", "4", "5", "6", "7", "8", "9", "", "0", "Clear", "Enter"}
        local key = keys[index]
        if key == "Clear" then
            pin = ""
            monitor.setCursorPos(5, 19)
            monitor.clearLine()
        elseif key == "Enter" then
            if #pin == 4 then  
                return pin 
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
        if response.message then
            monitor.write("Failed to create card: " .. response.message)
        else
            montior.write("Failed to create card")
        end
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
    rednet.send(databaseID, {type = "getBalance", cardNumber = cardNum}, "databaseQuery")
    local senderId, response = rednet.receive("databaseResponse")
    monitor.clear()
    if response.success == true then
        monitor.setCursorPos(1, 1)
        monitor.write("Your balance is: " .. response.balance)
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

    rednet.send(databaseID, {type = "checkCard", cardNumber = cardNum}, "databaseQuery")
    local senderId, response = rednet.receive("databaseResponse")
    if not response.exists then
        monitor.setCursorPos(1, 2)
        monitor.write("Card number does not exist. Please try again.")
        sleep(2)
        drawMainMenu()
        return
    end

    monitor.clear()
    monitor.setCursorPos(1, 1)
    monitor.write("Confirm items deposit?")
    drawButton(2, 4, 30, 3, "Confirm", colors.green)
    
    while true do
        local event, side, x, y = os.pullEvent("monitor_touch")
        if x >= 2 and x <= 32 and y >= 4 and y <= 7 then
            break
        end
    end

    rednet.send(turtleID, {command = "activate"}, "turtleCommand")
    monitor.clear()
    monitor.setCursorPos(1, 1)
    monitor.write("Waiting for items to be deposited...")

    local senderId, data, protocol = rednet.receive("itemData")
    if senderId == turtleID then
        local totalValue = 0
        local y_ind = 2

        local items = textutils.unserialize(data.items) 
        for itemName, itemCount in pairs(items) do
            local itemValue = itemValues[itemName]
            if itemValue then
                y_ind = y_ind + 1
                monitor.setCursorPos(1, y_ind)
                monitor.write("Item val " .. itemValue)
                local itemTotalValue = itemValue * itemCount
                y_ind = y_ind + 1
                monitor.setCursorPos(1, y_ind)
                monitor.write("Item prod " .. itemTotalValue)
                totalValue = totalValue + itemTotalValue
                y_ind = y_ind + 1
                monitor.setCursorPos(1, y_ind)
                monitor.write("Running total " .. totalValue)
            end
        end

        monitor.write("Got balance" .. totalValue)
        rednet.send(databaseID, {type = "updateBalance", amount = totalValue, playerID = cardNum}, "databaseQuery")
        monitor.setCursorPos(1, 2)
        monitor.write("Got balance" .. totalValue)
        monitor.setCursorPos(1, 3)
        monitor.write("Items processed and balance updated.")
        sleep(2)
    end
    drawMainMenu()
    rednet.close()
end

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
