local tellerMachineID = 6

-- GPS navigation function
function goTo(x, y, z)
    local curX, curY, curZ = gps.locate(5)
    if not curX then
        print("GPS not available")
        return false
    end

    -- Adjust height
    while curY < y do
        turtle.up()
        curY = curY + 1
    end
    while curY > y do
        turtle.down()
        curY = curY - 1
    end

    -- Adjust longitude
    while curX < x do
        turtle.forward()
        curX = curX + 1
    end
    while curX > x do
        turtle.back()
        curX = curX - 1
    end

    -- Adjust latitude
    while curZ < z do
        turtle.forward()
        curZ = curZ + 1
    end
    while curZ > z do
        turtle.back()
        curZ = curZ - 1
    end
    return true
end

-- Function to collect items from a chest
function collectItems()
    turtle.select(1)  -- Select the first slot
    while turtle.suck() do
        -- Collect items until the chest is empty
    end
end

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

-- Main routine modification to wait for activation command
function main()
    rednet.open("right")  -- Ensure the modem is open
    while true do
        local senderId, message, protocol = rednet.receive("turtleCommand")
        if protocol == "turtleCommand" and message.command == "activate" and senderId == tellerMachineID then
            -- Navigate to deposit chest
            if goTo(223, 67, -395) then
                collectItems()
                goTo(223, 67, -397)
                goTo(223, 64, -397)
                goTo(223, 64, -406)  
                sendItemData()
                depositItems()
                goTo(223, 64, -406)
                goTo(223, 64, -397)
                goTo(223, 67, -397)
            end
        end
    end
end

-- Run the main function
main()
