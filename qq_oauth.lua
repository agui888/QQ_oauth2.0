local uri_auth = [[https://graph.qq.com/oauth2.0/authorize]]
local uri_token = [[QQ/oauth2.0/token]]
local uri_me = [[QQ/oauth2.0/me]]
local uri_userInfo = [[QQ/user/get_simple_userinfo?format=json]]

local function GetTableArgs(vTable)
    local args
    for key, val in pairs(vTable) do
        if type(val) == "table" then
            if args == nil then
                args = GetTableArgs(val)
            else
                args = args.."&"..GetTableArgs(val)
            end
        else
            if args == nil then
                args = tostring(key).."="..tostring(val)
            else
                args = args.."&"..tostring(key).."="..tostring(val)
            end
        end
    end
    return args
end

local function Authorize()
	local args = GetTableArgs(ngx.req.get_uri_args())
	if args == nil then
		args = "state=test-XXXX-XXXX" 
	else
		args = args.."&state=test-XXXX"
	end

	local uri = uri_auth..	"?response_type=code&client_id="..tostring(ngx.var.client_id)..
							"&redirect_uri="..tostring(ngx.var.redirect_uri)..
							"&"..args
	
	return ngx.redirect(uri)	
end

local function ShowUserInfo()
	local args = GetTableArgs(ngx.req.get_uri_args())
	if args == nil then
		return ngx.exit(ngx.HTTP_NOT_ALLOWED)
	end
	--local _, _, state = string.find(res.body, ".*state=([^&]+)")
	--check for the arg:"state"

	local uri = uri_token.."?grant_type=authorization_code&client_id="..tostring(ngx.var.client_id)..
							"&client_secret="..tostring(ngx.var.client_secret)..
							"&redirect_uri="..tostring(ngx.var.redirect_uri)..
							"&"..args

	local res = ngx.location.capture(uri)
	if ngx.HTTP_OK ~= res.status then
		ngx.log(ngx.ERR, uri.." > "..res.body)
		return ngx.exit(res.status)
	end 

	local _, _, token = string.find(res.body, ".*access_token=([^&]+)")

	uri = uri_me.."?access_token="..token
	res = ngx.location.capture(uri)
	if ngx.HTTP_OK ~= res.status then
		ngx.log(ngx.ERR, uri.." > "..res.body)
		return ngx.exit(res.status)
	end 

	local _, _, clientId	= string.find(res.body, ".*\"client_id\"%s*:%s*\"([^\"]+)")
	local _, _, openId		= string.find(res.body, ".*\"openid\"%s*:%s*\"([^\"]+)")

	uri = uri_userInfo.."&access_token="..token.."&oauth_consumer_key="..clientId.."&openid="..openId
	res = ngx.location.capture(uri)
	if ngx.HTTP_OK ~= res.status then
		ngx.log(ngx.ERR, uri.." > "..res.body)
		return ngx.exit(res.status)
	end 

	local _, _, nickname	= string.find(res.body, ".*\"nickname\"%s*:%s*\"([^\"]+)")
	local _, _, gender		= string.find(res.body, ".*\"gender\"%s*:%s*\"([^\"]+)")
	local _, _, province	= string.find(res.body, ".*\"province\"%s*:%s*\"([^\"]+)")
	local _, _, city		= string.find(res.body, ".*\"city\"%s*:%s*\"([^\"]+)")

	--show info
	ngx.say("nickname:"..nickname)
	ngx.say("gender:"..gender)
	ngx.say("province:"..province)
	ngx.say("city:"..city)

	--save info  
	--todo...
end

if "/qq/oauth2.0/authorize" == ngx.var.uri then
	return Authorize()
elseif "/qq/oauth2.0/token" == ngx.var.uri then
	return ShowUserInfo()
else
	return ngx.exe(404)
end
