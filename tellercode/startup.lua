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
function drawButton(x, y, width, height, text, bgColor)
    monitor.setBackgroundColor(bgColor)
    for i = 0, height - 1 do
        monitor.setCursorPos(x, y + i)
        monitor.write(string.rep(" ", width))  -- Draw the button background
    end
    local textX = x + (width // 2) - (#text // 2)
    local textY = y + (height // 2)
    monitor.setCursorPos(textX, textY)
    monitor.write(text)
end

-- Main menu screen
function drawMainMenu()
    setupMonitor()
    drawButton(2, 2, 28, 3, "New Card", colors.red)
    drawButton(2, 6, 28, 3, "Enter Card Number", colors.red)
end

-- Screen to input card number
function drawCardInputScreen()
    setupMonitor()
    monitor.setCursorPos(2, 2)
    monitor.write("Enter Card Number:")
    monitor.setCursorPos(2, 4)
    monitor.setBackgroundColor(colors.white)
    monitor.write(string.rep(" ", 26))
    monitor.setCursorPos(2, 8)
    drawButton(2, 8, 28, 3, "Submit", colors.red)
end

-- Handle touch events
function handleTouchEvents()
    while true do
        local event, side, x, y = os.pullEvent("monitor_touch")
        if y >= 2 and y <= 4 then
            if x >= 2 and x <= 29 then
                return "new_card"
            end
        elseif y >= 6 and y <= 8 then
            if x >= 2 and x <= 29 then
                return "enter_card"
            end
        elseif y >= 8 and y <= 10 then
            if x >= 2 and x <= 29 then
                return "submit"
            end
        end
    end
end

-- Main server loop
function main()
    rednet.open("back")
    drawMainMenu()
    local action = handleTouchEvents()

    if action == "new_card" then
        -- Handle new card creation
        rednet.send(databaseID, {type = "createNewCard"}, "databaseQuery")
        local senderId, response = rednet.receive("databaseResponse")
        displayMessage(response.message)
    elseif action == "enter_card" then
        -- Handle card number input
        drawCardInputScreen()
        local cardNumber = read()
        -- Process card number...
    end
end

main()  -- Run the main function
