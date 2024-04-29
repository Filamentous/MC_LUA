local json = {}


function json.encode(table)
    return textutils.serialize(table)
end

function json.decode(jsonString)
    return textutils.unserialize(jsonString)
end

return json
