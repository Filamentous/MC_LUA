local tellerMachineID = 6

-- Helper function for movement with debugging
function move(steps, action, actionName)
    for i = 1, steps do
        action()
        print("Performed: " .. actionName .. " Step: " .. i)
    end
end

-- Collect items from a chest with debugging
function collectItems()
    turtle.select(1)  -- Select the first slot
    local count = 0
    while turtle.suck() do
        count = count + 1
        print("Collected item batch: " .. count)
    end
    print("Finished collecting items.")
end

-- Send item data to the teller machine
function sendItemData()
    local items = {}
    for slot = 1, 16 do
        local item = turtle.getItemDetail(slot)
        if item then
            table.insert(items, {name = item.name, count = item.count})
            print("Added " .. item.name .. " count: " .. item.count .. " to data packet.")
        end
    end

    rednet.open("right")
    rednet.send(tellerMachineID, {items = items}, "itemData")
    print("Sent item data to teller machine.")
    rednet.close()
end

-- Deposit all items into a chest below with debugging
function depositItems()
    for slot = 1, 15 do
        turtle.select(slot)
        turtle.dropDown()
        print("Dropped items from slot: " .. slot)
    end
    print("All items deposited.")
end

function checkAndRefuel()
    if turtle.getFuelLevel() < 50 then  -- Assume we need at least 50 fuel units to complete the sequence
        turtle.select(16)
        if turtle.refuel(1) then  -- Refuel with one item from the slot
            print("Refueled using item in slot coal in slot 16")
        end
        if turtle.getFuelLevel() < 50 then
            print("ADD FUEL TO SLOT 16")
            return false
        end
    end
    return true
end

-- Execute a sequence of predetermined movements and actions
function performSequence()
    if not checkAndRefuel() then
        return  -- Stop the sequence if not enough fuel
    end
    print("Starting sequence.")
    collectItems()
    move(1, turtle.back, "back")
    move(3, turtle.up, "up")
    move(9, turtle.back, "back")
    sendItemData()
    depositItems()
    move(9, turtle.forward, "forward")
    move(3, turtle.down, "down")
    move(1, turtle.forward, "forward")
    print("Sequence completed.")
end

-- Main routine waiting for activation command
function main()
    rednet.open("right")
    print("Rednet opened, waiting for activation command...")
    while true do
        local senderId, message, protocol = rednet.receive("turtleCommand")
        print("Received message with protocol: " .. tostring(protocol))
        if message.command == "activate" and senderId == tellerMachineID then
            print("Activation command received.")
            performSequence()
        end
    end
end

main()  -- Run the main function
