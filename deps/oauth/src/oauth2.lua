local Object = require('core').Object
local crypto = require('tls/lcrypto')
local http = require('http')
local https = require('https')
local qs = require('querystring')
local table = require('table')
local string = require('string')
local JSON = require('json')
local URL = require('url')

local h = require('./_helpers')

local OAuth = Object:extend()

function OAuth:initialize (opts)
  opts = opts or {}

  self.clientID = opts.clientID
  self.clientSecret = opts.clientSecret
  self.baseSite = opts.baseSite
  self.authorizeUrl = opts.authorizePath or '/oauth/authorize'
  self.accessTokenUrl = opts.accessTokenPath or '/oauth/access_token'
  self.customHeaders = opts.customHeaders or {}
  self.accessTokenName = 'access_token'
  self.authMethod = 'Bearer'
  self.useAuthorizationHeaderForGET = false
end

function OAuth:setAccessTokenName (_name)
  self.accessTokenName = _name
end

function OAuth:setAuthMethod (_authMethod)
  self.authMethod = _authMethod
end

function OAuth:setUseAuthorizationHeaderForGET (_useIt)
  self.useAuthorizationHeaderForGET = _useIt
end

function OAuth:getAuthorizeUrl (params)
  params = params or {}
  params['client_id'] = self.clientID
  return self.baseSite .. self.authorizeUrl .. '?' .. h.stringify(params)
end

function OAuth:_getAccessTokenUrl ()
  return self.baseSite .. self.accessTokenUrl
end

function OAuth:getOAuthAccessToken (code, params, callback)
  params = params or {}
  params['client_id'] = self.clientID
  params['client_secret'] = self.clientSecret

  local codeParam = (params.grant_type == 'refresh_token' and 'refresh_token') or 'code'
  params[codeParam] = code

  opts = {
    method = 'POST',
    post_body = h.stringify(params)
  }

  self:request(self:_getAccessTokenUrl(), opts, function (err, data, resp)
    if err then return callback(err) end

    -- As of http://tools.ietf.org/html/draft-ietf-oauth-v2-07
    -- responses should be in JSON
    local results, line, parseError = JSON.parse(data)
    if parseError then
      results = qs.parse(data)
    end

    local access_token = results['access_token']
    local refresh_token = results['refresh_token']

    callback(nil, access_token, refresh_token, results)
  end)
end

function OAuth:request (url, opts, callback)
  if not url or type(url) ~= 'string' then
    return error('Request url is required and should be a String value')
  end

  if type(opts) ~= 'table' then
    return error('Options should be a Table value')
  end

  if type(callback) ~= 'function' then
    return error('Callback function is required')
  end

  opts = opts or {}

  local parsedURL = URL.parse(url)
  if parsedURL.protocol == 'http' and not parsedURL.port then parsedURL.port = 80 end
  if parsedURL.protocol == 'https' and not parsedURL.port then parsedURL.port = 443 end

  local headers = {}

  for k, value in pairs(self.customHeaders) do
    headers[k] = value
  end

  opts.headers = opts.headers or {}
  for k, value in pairs(opts.headers) do
    headers[k] = value
  end

  headers['Host'] = parsedURL.host

  if not headers['User-Agent'] or headers['User-Agent'] == '' then
    headers['User-Agent'] = 'Luvit-oauth'
  end

  if opts.post_body then
    headers['Content-Length'] = #opts.post_body
  else
    headers['Content-Length'] = 0
  end

  headers['Content-Type'] = opts.post_content_type or 'application/x-www-form-urlencoded'

  if not parsedURL.query or parsedURL.query == '' then parsedURL.query = {} end

  if opts.access_token and (not headers['Authorization'] or headers['Authorization'] == '') then
    parsedURL.query[self.accessTokenName] = opts.access_token
  end

  local queryString = h.stringify(parsedURL.query)
  if queryString ~= '' then queryString =  '?' .. queryString end

  local path = parsedURL.pathname .. queryString

  local allowEarlyClose = h.isAnEarlyCloseHost(parsedURL.hostname)
  local data = ''
  local callbackCalled = false
  local function passBackControl (response)
    if callbackCalled then return end

    callbackCalled = true
    if response.statusCode ~= 200 and response.statusCode ~= 301 and response.statusCode ~= 302 then
      callback({statusCode = response.statusCode, data = data}, data, response)
    else
      callback(nil, data, response)
    end
  end
  local request = self:_createClient(parsedURL.port, parsedURL.hostname, opts.method, path, headers, parsedURL.protocol)
  request:on('response', function (response)
    response:on('data', function (chunk)
      data = data .. chunk
    end)
    response:on('close', function (err)
      if allowEarlyClose then
        passBackControl(response)
      end
    end)
    response:on('end', function ()
      passBackControl(response)
    end)
  end)
  request:on('error', function (response)
    if allowEarlyClose then
      passBackControl(response)
    end
  end)
  if (opts.method == 'POST' or opts.method == 'PUT') and opts.post_body ~= nil and opts.post_body ~= '' then
    request:write(opts.post_body)
  end
  request:done()
end

function OAuth:_createClient (port, hostname, method, path, headers, protocol)
  local options = {
    host = hostname,
    port = port,
    path = path,
    method = method,
    headers = headers
  }

  local httpModel
  if (protocol == 'https') then httpModel = https else httpModel = http end
  return httpModel.request(options)
end

function OAuth:buildAuthHeader (access_token)
  return self.authMethod .. ' ' .. access_token
end

-- shorteners
function OAuth:get(url, opts, callback)
  opts, callback = self:_shortenerValidator('GET', opts, callback)
  opts.headers = opts.headers or {}
  if self.useAuthorizationHeaderForGET then
    opts.headers['Authorization'] = self:buildAuthHeader(opts.access_token)
    opts.access_token = nil
  end
  return self:request(url, opts, callback)
end

function OAuth:post(url, opts, callback)
  opts, callback = self:_shortenerValidator('POST', opts, callback)
  return self:request(url, opts, callback)
end

function OAuth:put(url, opts, callback)
  opts, callback = self:_shortenerValidator('PUT', opts, callback)
  return self:request(url, opts, callback)
end

function OAuth:patch(url, opts, callback)
  opts, callback = self:_shortenerValidator('PATCH', opts, callback)
  return self:request(url, opts, callback)
end

function OAuth:delete(url, opts, callback)
  opts, callback = self:_shortenerValidator('DELETE', opts, callback)
  return self:request(url, opts, callback)
end

function OAuth:_shortenerValidator(method, opts, callback)
  if type(opts) == 'function' then
    callback = opts
    opts = {}
  else
    opts = opts or {}
  end

  opts.method = method
  return opts, callback
end

return OAuth
