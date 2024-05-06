local monitor = peripheral.wrap("top")
local modemSide = "right"
rednet.open(modemSide)
local vaultChannel = 1
local responseChannel = 2

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
    local keys = {"1", "2", "3", "4", "5", "6", "7", "8", "9", "Clear", "0", "Enter"}
    local yPos = 4
    for i, key in ipairs(keys) do
        local xPos = 2 + ((i-1) % 3) * 10
        if key == "Enter" then
            drawButton(xPos, yPos, 8, 3, key, colors.lime)
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
        local keys = {"1", "2", "3", "4", "5", "6", "7", "8", "9", "", "0", "Clear", "Enter"}
        local key = keys[index]
        if key == "Clear" then
            pin = ""
            monitor.setCursorPos(5, 19)
            monitor.clearLine()
        elseif key == "Enter" then
            if #pin == 6 then  
                return pin 
            end
        elseif key ~= "" and key ~= nil then
            pin = pin .. key
            monitor.setCursorPos(5, 19)
            monitor.clearLine()
            monitor.write(pin)
        end
        if #pin == 6 then
            return pin
        end
    end
end

function sendPinToVault(pin)
    rednet.send(vaultChannel, pin)
    local id, message = rednet.receive(responseChannel, 10) -- wait for 10 seconds
    if message == "success" then
        print("Access Granted")
    else
        print("Access Denied")
    end
end

-- Main function to draw the pad and handle inputs
function main()
    drawPinPad()
    local pin = handlePinPadInput()
    sendPinToVault(pin)
end

main()