-- Load necessary APIs
os.loadAPI("json")
local monitor = peripheral.wrap("top")  -- Monitor is above the computer
local databaseID = 5  -- The ID of the central database computer

-- General display setup
function setupMonitor()
    monitor.setTextScale(0.5)
    monitor.setBackgroundColor(colors.black)
    monitor.clear()
end

-- Function to draw a button
function drawButton(x1, y1, x2, y2, text, bgColor, textColor)
    paintutils.drawFilledBox(x1, y1, x2, y2, bgColor)
    local width = x2 - x1 + 1
    local height = y2 - y1 + 1
    local textX = x1 + (width - #text) // 2
    local textY = y1 + (height // 2)
    monitor.setTextColor(textColor)
    monitor.setCursorPos(textX, textY)
    monitor.write(text)
end

-- Draws the main menu
function drawMainMenu()
    setupMonitor()
    drawButton(2, 3, 27, 6, "New Card", colors.red, colors.white)
    drawButton(2, 8, 27, 11, "Enter Card Number", colors.red, colors.white)
end

-- Function to handle touch interaction
function handleTouchEvents()
    while true do
        local event, side, x, y = os.pullEvent("monitor_touch")
        if x >= 2 and x <= 27 then
            if y >= 3 and y <= 6 then
                return "new_card"
            elseif y >= 8 and y <= 11 then
                return "enter_card"
            end
        end
    end
end

-- Function for creating a new card
function createNewCard()
    rednet.open("back")
    local cardNumber = math.random(1000, 9999)  -- Simulate card number generation
    rednet.send(databaseID, {type = "createNewCard", cardNumber = cardNumber}, "databaseQuery")
    local _, response = rednet.receive("databaseResponse")
    monitor.clear()
    if response.success then
        monitor.setCursorPos(1, 1)
        monitor.write("Card " .. cardNumber .. " created successfully!")
    else
        monitor.setCursorPos(1, 1)
        monitor.write("Failed to create card. Error: " .. response.message)
    end
    sleep(2)
    drawMainMenu()
    rednet.close()
end

-- Function for entering card number
function enterCardNumber()
    setupMonitor()
    monitor.setCursorPos(1, 1)
    monitor.write("Please enter your card number:")
    local cardNumber = tonumber(read())
    rednet.open("back")
    rednet.send(databaseID, {type = "checkCard", cardNumber = cardNumber}, "databaseQuery")
    local _, response = rednet.receive("databaseResponse")
    rednet.close()
    monitor.clear()
    if response.exists then
        monitor.setCursorPos(1, 1)
        monitor.write("Card number " .. cardNumber .. " exists.")
        sleep(2)
    else
        monitor.setCursorPos(1, 1)
        monitor.write("Card number does not exist.")
        sleep(2)
    end
    drawMainMenu()
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
        end
    end
end

main()  -- Run the main function
