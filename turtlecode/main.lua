local tellerMachineID = 6

-- Function to move turtle a set number of steps
function move(steps, action)
    for i = 1, steps do
        action()
    end
end

-- Function to collect items from a chest
function collectItems()
    turtle.select(1)  -- Select the first slot
    while turtle.suck() do
        -- Keep collecting items until the chest is empty
    end
end

-- Function to send item data to the teller machine
function sendItemData()
    local items = {}
    for slot = 1, 16 do
        local item = turtle.getItemDetail(slot)
        if item then
            table.insert(items, {name = item.name, count = item.count})
        end
    end

    rednet.open("right")
    rednet.send(tellerMachineID, {items = items}, "itemData")
    rednet.close()
end

-- Function to deposit all items into a chest below
function depositItems()
    for slot = 1, 16 do
        turtle.select(slot)
        turtle.dropDown()  -- Drop all items from the current slot downwards into the chest
    end
end

-- Navigation to predefined locations and actions
function performSequence()
    -- Starting at initial position, assume it starts at 223, 67, -395 (player input chest location)
    collectItems()  -- Collect from player input chest
    move(1, turtle.back)  -- Move back to 223, 67, -397
    move(3, turtle.up)  -- Move up to 223, 70, -397
    move(9, turtle.back)  -- Move back to 223, 70, -406 (deposit location)
    sendItemData()  -- Send collected items data
    depositItems()  -- Deposit items into the chest below
    move(9, turtle.forward)  -- Move forward to 223, 70, -397
    move(3, turtle.down)  -- Move down to 223, 67, -397
    move(1, turtle.forward)  -- Return to starting position at 223, 67, -395
end

-- Main routine waiting for activation command
function main()
    rednet.open("right")  -- Ensure the modem is open
    while true do
        local senderId, message, protocol = rednet.receive("turtleCommand")
        if protocol == "turtleCommand" and message.command == "activate" and senderId == tellerMachineID then
            performSequence()
        end
    end
end

-- Run the main function
main()
