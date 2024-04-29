local tellerMachineID = 6


function move(steps, action, actionName)
    for i = 1, steps do
        action()
        print("Performed: " .. actionName .. " Step: " .. i)
        sleep(0.85) 
    end
end

function collectItems()
    turtle.select(1)
    local count = 0
    while turtle.suck() do
        count = count + 1
        print("Collected item batch: " .. count)
        sleep(0.1)
    end
    print("Finished collecting items.")
end

function sendItemData()
    local items = {}
    for slot = 1, 15 do
        local item = turtle.getItemDetail(slot)
        if item then
            if items[item.name] then
                items[item.name] = items[item.name] + item.count
            else
                items[item.name] = item.count
            end
            print("Updated " .. item.name .. " count: " .. items[item.name])
        end
        sleep(0.1)
    end

    local serializedData = textutils.serialize(items)
    rednet.open("right")
    rednet.send(tellerMachineID, {items = serializedData}, "itemData")
    print("Sent item data to teller machine as serialized string.")
    rednet.close()
end

function depositItems()
    for slot = 1, 15 do
        turtle.select(slot)
        turtle.dropDown()
        print("Dropped items from slot: " .. slot)
        sleep(0.1)
    end
    print("All items deposited.")
end

function checkAndRefuel()
    if turtle.getFuelLevel() < 50 then
        turtle.select(16)
        if turtle.refuel(1) then
            print("Refueled using item in slot coal in slot 16")
        end
        if turtle.getFuelLevel() < 50 then
            print("ADD FUEL TO SLOT 16")
            return false
        end
    end
    return true
end

function performSequence()
    if not checkAndRefuel() then
        return
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

main()
