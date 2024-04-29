local monitor = peripheral.wrap("top")
local speaker = peripheral.find("speaker")
local modem = peripheral.wrap("back")

local symbols = {"Cherry", "Bell", "BAR", "7", "Diamond"}
local betAmount = 2
local jackpot = 64
local databaseID = 5

rednet.open("back")

function getPlayerIDFromScreen()
    monitor.clear()
    monitor.setCursorPos(1, 1)
    monitor.write("Please enter your Player ID:")
    local input = read()
    return tonumber(input)
end

function checkBalance(playerID)
    rednet.send(databaseID, {type = "checkBalance", playerID = playerID}, "databaseQuery")
    local id, message = rednet.receive("databaseResponse")
    return message.balance
end

function updateBalance(playerID, amount)
    rednet.send(databaseID, {type = "updateBalance", playerID = playerID, amount = amount}, "databaseQuery")
end

function spinReels()
    local results = {}
    for i = 1, 3 do
        table.insert(results, symbols[math.random(#symbols)])
    end
    return results
end

function calculateWinnings(results)
    if results[1] == results[2] and results[2] == results[3] then
        return results[1] == "7" and jackpot or jackpot / 4
    end
    return 0
end

function playResultSound(winnings)
    if winnings > 0 then
        speaker.playSound("file:///win.mp3", 0.3)
    else
        speaker.playSound("file:///loss.mp3", 0.3)
    end
end

function displayInfo(info, row)
    monitor.clear()
    monitor.setCursorPos(1, row)
    monitor.write(info)
end

function playSlotMachine(playerID)
    local balance = checkBalance(playerID)
    if balance < betAmount then
        displayInfo("Insufficient funds to play.", 2)
        return
    end

    updateBalance(playerID, -betAmount)
    displayInfo("Spinning... Press any key to stop!", 3)
    os.pullEvent("key")
    local results = spinReels()
    local winnings = calculateWinnings(results)
    updateBalance(playerID, winnings)
    balance = checkBalance(playerID)

    displayInfo("Results: " .. table.concat(results, " | "), 4)
    displayInfo("Winnings: " .. winnings, 5)
    displayInfo("New Balance: " .. balance, 6)
    playResultSound(winnings)
end

function main()
    monitor.setTextScale(0.5)
    monitor.clear()
    local playerID = getPlayerIDFromScreen()
    if playerID then
        playSlotMachine(playerID)
    else
        displayInfo("Invalid Player ID entered.", 1)
    end
end

main()