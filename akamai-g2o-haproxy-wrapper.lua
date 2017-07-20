package.path = '/etc/haproxy/?.lua;' .. package.path
require("akamai-g2o")

-- Decides back-end based on Success and Failure received from validation API
core.register_fetches("g2o_validation_fetch", function(txn, version, secret, delta, failure_backend, success_backend)
    local data_header = txn.sf:req_fhdr("x-akamai-g2o-auth-data")
    local signature_header = txn.sf:req_fhdr("x-akamai-g2o-auth-sign")
    local result, message = akamai_g2o_validate(txn.sf:path(), data_header, signature_header, tonumber(version), secret, tonumber(delta))
    if result == false then
        core.Warning("G2O validation failed: " .. message)
        return failure_backend
    end

    return success_backend
end)

-- Failure service
core.register_service("g2o_failure_service", "http", function(applet)
    local response = "Unauthorized Access"
    applet:set_status(400)
    applet:add_header("content-length", string.len(response))
    applet:add_header("content-type", "text/plain")
    applet:start_response()
    applet:send(response)
end)
