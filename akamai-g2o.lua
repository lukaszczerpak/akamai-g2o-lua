local hmac = require('openssl.hmac')
local digest = require('openssl.digest')

local function isempty(s)
    return s == nil or s == ''
end

local function tohex(b)
    local x = ""
    for i = 1, #b do
        x = x .. string.format("%.2x", string.byte(b, i))
    end
    return x
end

-- character table string
local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'

-- encoding
function enc(data)
    return ((data:gsub('.', function(x)
        local r, b = '', x:byte()
        for i = 8, 1, -1 do r = r .. (b % 2 ^ i - b % 2 ^ (i - 1) > 0 and '1' or '0') end
        return r;
    end) .. '0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
        if (#x < 6) then return '' end
        local c = 0
        for i = 1, 6 do c = c + (x:sub(i, i) == '1' and 2 ^ (6 - i) or 0) end
        return b:sub(c + 1, c + 1)
    end) .. ({ '', '==', '=' })[#data % 3 + 1])
end

akamai_g2o_versions = {
    function(secret, data, path)
        local hash = digest.new("md5")
        hash:update(secret)
        hash:update(data)
        hash:update(path)
        return enc(hash:final())
    end,
    function(secret, data, path)
        local hash1 = digest.new("md5")
        hash1:update(secret)
        hash1:update(data)
        hash1:update(path)

        local hash2 = digest.new("md5")
        hash2:update(secret)
        hash2:update(hash1:final())
        return enc(hash2:final())
    end,
    function(secret, data, path)
        local hash = hmac.new(secret, "md5")
        hash:update(data)
        hash:update(path)
        return enc(hash:final())
    end,
    function(secret, data, path)
        local hash = hmac.new(secret, "sha1")
        hash:update(data)
        hash:update(path)
        return enc(hash:final())
    end,
    function(secret, data, path)
        local hash = hmac.new(secret, "sha256")
        hash:update(data)
        hash:update(path)
        return enc(hash:final())
    end
}

function akamai_g2o_timestamp_verify(data_header, curr_ts, delta)
    local ts = data_header:match("%d+,%s*[%d%.:]+,%s*[%d%.:]+,%s*(%d+),.*")
    if (math.abs(tonumber(ts) - tonumber(curr_ts)) <= delta) then
        return true
    end
    return false
end

function akamai_g2o_validate(path, data_header, signature_header, version, secret, delta)
    -- check if g2o headers are present
    if (isempty(data_header)) then
        return false, "no data header"
    end
    if (isempty(signature_header)) then
        return false, "no signature header"
    end

    -- validate signature
    local expected_signature = akamai_g2o_versions[version](secret, data_header, path)
    if signature_header ~= expected_signature then
        return false, "wrong signature"
    end

    -- check timestamp
    if akamai_g2o_timestamp_verify(data_header, os.time(), delta) == false then
        return false, "expired signature"
    end

    return true, "ok"
end