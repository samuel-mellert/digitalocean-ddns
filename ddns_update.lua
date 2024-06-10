local http = require "resty.http"
local json = require "cjson"

local function get_env_variable(name)
    local var = os.getenv(name)
    if not var then
        ngx.log(ngx.ERR, "Environment variable " .. name .. " is not set")
        ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
    end
    ngx.log(ngx.INFO, "Environment variable " .. name .. " is set to: " .. var)
    return var
end

local DO_AUTH_TOKEN = get_env_variable("DO_AUTH_TOKEN")
local DO_DOMAIN_NAME = get_env_variable("DO_DOMAIN_NAME")
local DO_SUBDOMAIN = get_env_variable("DO_SUBDOMAIN")
local DDNS_PASSWORD = get_env_variable("DDNS_PASSWORD")

local headers = ngx.req.get_headers()
local auth = headers["Authorization"]
if not auth or auth:find("Basic ") ~= 1 then
    ngx.status = ngx.HTTP_UNAUTHORIZED
    ngx.say("Unauthorized")
    return
end

local encoded_credentials = auth:sub(7)
local decoded_credentials = ngx.decode_base64(encoded_credentials)
local username, password = decoded_credentials:match("([^:]+):([^:]+)")

if password ~= DDNS_PASSWORD then
    ngx.status = ngx.HTTP_UNAUTHORIZED
    ngx.say("Unauthorized")
    return
end

local args = ngx.req.get_uri_args()
local hostname = args.hostname
local ipv4 = args.myip
local ipv6 = args.myipv6

if hostname ~= (DO_SUBDOMAIN .. "." .. DO_DOMAIN_NAME) then
    ngx.status = ngx.HTTP_BAD_REQUEST
    ngx.say("Invalid hostname")
    return
end

local httpc = http.new()
httpc:set_timeout(5000)

local function get_record_id(record_type)
    local res, err = httpc:request_uri("https://api.digitalocean.com/v2/domains/" .. DO_DOMAIN_NAME .. "/records?type=" .. record_type, {
        method = "GET",
        headers = {
            ["Authorization"] = "Bearer " .. DO_AUTH_TOKEN,
            ["Content-Type"] = "application/json",
        }
    })

    if not res then
        ngx.log(ngx.ERR, "Failed to request: ", err)
        return nil, err
    end

    if res.status ~= 200 then
        ngx.log(ngx.ERR, "Non-200 response: ", res.body)
        return nil, res.body
    end    

    local body = json.decode(res.body)
    for _, record in ipairs(body.domain_records) do
        if record.type == record_type and record.name == DO_SUBDOMAIN then            
            ngx.log(ngx.INFO, 
                "Found record {id: ", record.id, 
                ", type: ", record.type, 
                ", name: ", record.name, 
                ", value: ", record.value, 
                ", ttl: ", record.ttl, 
                "}")
            return record.id
        end
    end

    return nil, "Record not found"
end

local function update_record(record_id, ip, record_type)
    local res, err = httpc:request_uri("https://api.digitalocean.com/v2/domains/" .. DO_DOMAIN_NAME .. "/records/" .. record_id, {
        method = "PUT",
        body = json.encode({ data = ip, type = record_type }),
        headers = {
            ["Authorization"] = "Bearer " .. DO_AUTH_TOKEN,
            ["Content-Type"] = "application/json",
        }
    })

    if not res then
        ngx.log(ngx.ERR, "Failed to request: ", err)
        return false
    end

    if res.status ~= 200 then
        ngx.log(ngx.ERR, "Non-200 response: ", res.body)
        return false
    end

    ngx.log(ngx.INFO, "Updated " .. record_type .. " to: " .. ip)

    return true
end

if ipv4 then
    local record_id, err = get_record_id("A")
    if not record_id then
        ngx.log(ngx.ERR, "Error getting A record ID: ", err)
        ngx.status = ngx.HTTP_INTERNAL_SERVER_ERROR
        ngx.say(err)
        return
    end

    if not update_record(record_id, ipv4, "A") then
        ngx.log(ngx.ERR, "Error updating A record")
        ngx.status = ngx.HTTP_INTERNAL_SERVER_ERROR
        ngx.say("Error updating A record")
        return
    end
end

if ipv6 then
    local record_id, err = get_record_id("AAAA")
    if not record_id then
        ngx.log(ngx.ERR, "Error getting AAAA record ID: ", err)
        ngx.status = ngx.HTTP_INTERNAL_SERVER_ERROR
        ngx.say(err)
        return
    end

    if not update_record(record_id, ipv6, "AAAA") then
        ngx.log(ngx.ERR, "Error updating AAAA record")
        ngx.status = ngx.HTTP_INTERNAL_SERVER_ERROR
        ngx.say("Error updating AAAA record")
        return
    end
end

ngx.say("Update successful")
