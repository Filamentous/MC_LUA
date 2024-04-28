-- Load necessary APIs
os.loadAPI("json")

local monitor = peripheral.wrap("top")  -- Monitor is above the computer
local databaseID = 5  -- The ID of the central database computer
local turtleID =  -- Define your turtle ID

-- Setup monitor display
function setupGUI()
    monitor.setTextScale(0.5)
    monitor.clear()
    monitor.setCursorPos(1, 1)
    monitor.write("1. New Card")
    monitor.setCursorPos(1, 3)
    monitor.write("2. Enter Card Number")
end

-- Function to display a numeric pad for entering a 4-digit number
function numericInput(prompt)
    monitor.clear()
    monitor.setCursorPos(1, 1)
    monitor.write(prompt)
    monitor.setCursorPos(1, 2)
    local input = ""
    while true do
        local event, side, x, y = os.pullEvent("monitor_touch")
        -- Define touch areas for numeric input
        -- This is a placeholder: you should define actual areas based on your monitor setup
        if y == 4 then input = input .. "1" end  -- Example for '1'
        -- Add conditions for other numbers and a delete function
        if #input == 4 then break end  -- Exit after 4 digits
        monitor.setCursorPos(1, 2)
        monitor.write(input .. "_")
    end
    return tonumber(input)
end

-- Function to handle user selection from the main menu
function handleMenuSelection()
    while true do
        local event, side, x, y = os.pullEvent("monitor_touch")
        if y == 1 then  -- New card option
            return true, 0  -- True indicates new card, 0 is a dummy player ID
        elseif y == 3 then  -- Enter card number option
            local playerID = numericInput("Enter Your 4-Digit ID:")
            if playerID then
                return false, playerID
            end
        end
    end
end

-- Function to activate the turtle
function activateTurtle()
    rednet.open("back")
    rednet.send(turtleID, {command = "activate"}, "turtleCommand")
    rednet.close()
end

-- Main server loop
function main()
    rednet.open("back")
    setupGUI()
    while true do
        local newCard, playerID = handleMenuSelection()
        if newCard then
            rednet.send(databaseID, {type = "createNewCard"}, "databaseQuery")
            local senderId, response = rednet.receive("databaseResponse")
            monitor.clear()
            monitor.write(response.message)
        else
            monitor.clear()
            monitor.write("Insert items and press 'Done'")
            os.pullEvent("monitor_touch")  -- Wait for the 'Done' touch
            activateTurtle()  -- Trigger the turtle to start its job
        end
        sleep(5)  -- Give some delay before restarting the loop
        setupGUI()  -- Redisplay the main menu
    end
end

main()  -- Run the main function
