require 'akamai-g2o'
require 'apache2'

function akamai_g2o_validate_apache(r, version, secret, delta)
    if r.is_initial_req == false then
        return apache2.AUTHZ_GRANTED
    end
    local data_header = r.headers_in['x-akamai-g2o-auth-data']
    local signature_header = r.headers_in['x-akamai-g2o-auth-sign']
    local path = r.unparsed_uri
    local result, message = akamai_g2o_validate(path, data_header, signature_header, tonumber(version), secret, tonumber(delta))
    if result == false then
        r:warn(message)
        return apache2.AUTHZ_DENIED
    end
    return apache2.AUTHZ_GRANTED
end