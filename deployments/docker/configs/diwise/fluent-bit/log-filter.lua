
json = require "json"

function docker_log_filter(tag, timestamp, record)
    log_str = record["log"]
    new_record = json.parse(log_str)

    if new_record["level"] == "DEBUG" then
        return -1, 0, 0
    end

    return 2, timestamp, new_record
end
