local monitor = peripheral.wrap("top")
local redstone = peripheral.wrap("bottom")
local databaseID = 5  -- ID of your database computer
local turtleID = 8    -- ID of your turtle

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
    drawButton(2, 14, 30, 3, "Deposit Items", colors.blue)
end

function drawPinPad()
    setupMonitor()
    local keys = {"1", "2", "3", "4", "5", "6", "7", "8", "9", "Clear", "0", "Enter"}
    local yPos = 4
    for i, key in ipairs(keys) do
        local xPos = 2 + ((i-1) % 3) * 10
        if i > 9 then xPos = 12 end -- Adjust for bottom row
        drawButton(xPos, yPos, 8, 3, key, colors.gray)
        if i % 3 == 0 then yPos = yPos + 4 end
    end
end

function handlePinPadInput()
    local pin = ""
    while true do
        local event, side, x, y = os.pullEvent("monitor_touch")
        -- Determine button based on coordinates
        local row = math.floor((y - 4) / 4)
        local col = (x - 2) / 10
        local index = row * 3 + col + 1
        if index >= 10 then index = index + 1 end -- Adjust index for bottom row buttons
        local key = {"1", "2", "3", "4", "5", "6", "7", "8", "9", "", "0", ""}[index]
        if y >= 16 then
            if x <= 10 then
                pin = "" -- Clear button
            elseif x >= 22 then
                return pin -- Enter button
            end
        elseif key ~= "" then
            pin = pin .. key
            if #pin == 4 then return pin end -- Return pin if 4 digits are entered
        end
        -- Update the display to show the current pin
        monitor.setCursorPos(5, 19)
        monitor.clearLine()
        monitor.write(pin)
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
    local cardNumber = handlePinPadInput()
    rednet.open("back")
    rednet.send(databaseID, {type = "createNewCard", cardNumber = cardNumber}, "databaseQuery")
    local senderId, response = rednet.receive("databaseResponse")
    monitor.clear()
    if response.success then
        monitor.setCursorPos(1, 1)
        monitor.write("Card " .. cardNumber .. " created successfully!")
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
    local cardNumber = handlePinPadInput()
    rednet.open("back")
    rednet.send(databaseID, {type = "checkCard", cardNumber = cardNumber}, "databaseQuery")
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

function depositItemsAndActivateTurtle()
    monitor.clear()
    monitor.setCursorPos(1, 1)
    monitor.write("Please deposit your items and press any key when done.")
    os.pullEvent("key")  -- Wait for user to press a key after depositing items
    rednet.open("back")
    rednet.send(turtleID, {command = "activate"}, "turtleCommand")
    monitor.write("Processing items...")
    local senderId, message, protocol = rednet.receive("itemData")
    if protocol == "itemData" and senderId == turtleID then
        -- Assume code to process and update items here
        monitor.setCursorPos(1, 2)
        monitor.write("Items processed successfully.")
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
            depositItemsAndActivateTurtle()
        end
    end
end

main()
