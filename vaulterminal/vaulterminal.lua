local monitor = peripheral.wrap("top")
local modemSide = "right"
rednet.open(modemSide)
local vaultChannel = "vaultQuery"
local responseChannel = "vaultResponse"

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

function drawPinPad()
    setupMonitor()
    local keys = {"1", "2", "3", "4", "5", "6", "7", "8", "9", "Clear", "0", "Enter", "Close Vault"}
    local yPos = 4
    for i, key in ipairs(keys) do
        local xPos = 2 + ((i-1) % 3) * 10
        if key == "Enter" then
            drawButton(xPos, yPos, 8, 3, key, colors.lime)
        elseif key == "Close Vault" then
            drawButton(xPos, yPos, 8, 3, key, colors.red)
        else
            drawButton(xPos, yPos, 8, 3, key, colors.green)
        end
        if i % 3 == 0 then yPos = yPos + 4 end
    end
end

function handlePinPadInput()
    local pin = ""
    while true do
        local event, side, x, y = os.pullEvent("monitor_touch")
        local row = math.floor((y - 3) / 4)
        local col = math.floor((x - 1) / 10)
        local index = row * 3 + col + 1
        if index > 9 then index = index + 3 end
        local keys = {"1", "2", "3", "4", "5", "6", "7", "8", "9", "", "0", "Clear", "Enter", "Close Vault"}
        local key = keys[index]
        if key == "Clear" then
            pin = ""
            monitor.setCursorPos(5, 19)
            monitor.clearLine()
        elseif key == "Enter" then
            if #pin == 6 then  
                return pin, "enter"
            end
        elseif key == "Close Vault" then
            rednet.send(3, {action="close"}, vaultChannel)
            return "", "close"
        elseif key ~= "" and key ~= nil then
            pin = pin .. key
            monitor.setCursorPos(5, 19)
            monitor.clearLine()
            monitor.write(pin)
        end
        if #pin == 6 then
            return pin, "enter"
        end
    end
end

function sendPinToVault(pin, action)
    rednet.send(3, {pin = pin, action = action}, vaultChannel)  -- Include action type in the message
    local id, message = rednet.receive(responseChannel, 10) -- wait for 10 seconds
    monitor.setCursorPos(1, 20)
    monitor.clearLine()
    if message == "success" then
        monitor.write("Access Granted")
    else
        monitor.write("Access Denied")
    end
end

function main()
    while true do
        drawPinPad()
        local pin, action = handlePinPadInput()
        sendPinToVault(pin, action)
    end
end

main()