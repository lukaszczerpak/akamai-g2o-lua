require("akamai-g2o")

function akamai_g2o_validate_nginx(version, secret, delta)
    local data_header = ngx.req.get_headers()["x-akamai-g2o-auth-data"]
    local signature_header = ngx.req.get_headers()["x-akamai-g2o-auth-sign"]
    local path = ngx.var.request_uri
    local result, message = akamai_g2o_validate(path, data_header, signature_header, version, secret, delta)
    if result == false then
        ngx.log(ngx.WARN, message)
        ngx.exit(ngx.HTTP_BAD_REQUEST)
    end
end