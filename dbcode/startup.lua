-- Database storage setup
local balances = {}
local authorizedID = 6  -- ID of the authorized teller computer

-- Load existing data
if fs.exists("balances.txt") then
    local file = fs.open("balances.txt", "r")
    balances = textutils.unserialize(file.readAll())
    file.close()
end

-- Function to update balance and write to file
function updateBalance(playerID, amount)
    balances[playerID] = (balances[playerID] or 0) + amount
    writeToFile()
end

-- Function to handle new card/account creation
function createNewCard(playerID)
    if balances[playerID] then
        return false, "Account already exists."
    else
        balances[playerID] = 0
        writeToFile()
        return true, "New account created."
    end
end

-- General function to write changes to file
function writeToFile()
    local file = fs.open("balances.txt", "w")
    file.write(textutils.serialize(balances))
    file.close()
end

-- Server loop to handle requests
function main()
    rednet.open("back")
    while true do
        local senderId, message, protocol = rednet.receive("databaseQuery")
        if senderId == authorizedID then  -- Check if the sender is authorized
            if message.type == "updateBalance" and message.playerID and message.amount then
                updateBalance(message.playerID, message.amount)
            elseif message.type == "createNewCard" and message.playerID then
                local success, response = createNewCard(message.playerID)
                rednet.send(senderId, {success = success, response = response}, "databaseResponse")
            end
        else
            print("Unauthorized access attempt from ID " .. senderId)
        end
    end
end

-- Run the main function
main()
