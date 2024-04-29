local tellerMachineID = 6

-- Helper function for movement with debugging and delays
function move(steps, action, actionName)
    for i = 1, steps do
        action()
        print("Performed: " .. actionName .. " Step: " .. i)
        sleep(0.85) 
    end
end

-- Collect items from a chest with debugging
function collectItems()
    turtle.select(1)  -- Select the first slot
    local count = 0
    while turtle.suck() do
        count = count + 1
        print("Collected item batch: " .. count)
        sleep(0.1)  -- Short delay to stabilize item collection
    end
    print("Finished collecting items.")
end

-- Send item data to the teller machine
function sendItemData()
    local items = {}  -- Dictionary to store item counts
    for slot = 1, 15 do  -- Iterate over 15 slots
        local item = turtle.getItemDetail(slot)
        if item then
            if items[item.name] then
                items[item.name] = items[item.name] + item.count
            else
                items[item.name] = item.count
            end
            print("Updated " .. item.name .. " count: " .. items[item.name])
        end
        sleep(0.1)  -- Allow time for item processing
    end

    local serializedData = textutils.serialize(items)
    rednet.open("right")
    rednet.send(tellerMachineID, {items = serializedData}, "itemData")
    print("Sent item data to teller machine as serialized string.")
    rednet.close()



-- Deposit all items into a chest below with debugging
function depositItems()
    for slot = 1, 15 do
        turtle.select(slot)
        turtle.dropDown()
        print("Dropped items from slot: " .. slot)
        sleep(0.1)  -- Allows time for items to drop
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
    move(3, turtle.down, "down")
    move(9, turtle.back, "back")
    move(5, turtle.down, "down")
    sendItemData()
    depositItems()
    move(5, turtle.up, "up")
    move(9, turtle.forward, "forward")
    move(3, turtle.up, "up")
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
