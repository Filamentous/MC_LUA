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
    monitor.setCursorPos(x + 2, y + (height // 2))
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
    local cardNumber = math.random(1000, 9999)  -- Simulated card number generation
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
    monitor.setCursorPos(1, 1)
    monitor.write("Enter your card number:")
    local cardNumber = tonumber(read())
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
