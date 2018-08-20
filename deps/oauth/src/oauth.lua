local Object = require('core').Object
local crypto = require('tls/lcrypto')
local http = require('http')
local https = require('https')
local qs = require('querystring')
local URL = require('url')
local table = require('table')
local string = require('string')

-- helper functions
local h = require('./_helpers')
local generateTimestamp, generateNonce, oauthEncode, base64Encode = h.generateTimestamp, h.generateNonce, h.oauthEncode, h.base64Encode

local OAuth = Object:extend()

function OAuth:initialize (opts)
  opts = opts or {}

  self.requestUrl = opts.requestUrl
  self.accessUrl = opts.accessUrl
  self.consumer_key = opts.consumerKey
  self.consumer_secret = opts.consumerSecret
  self.signature_method = opts.signature_method or 'HMAC-SHA1'
  if (self.signature_method ~= 'HMAC-SHA1' and
    self.signature_method ~= 'PLAINTEXT' and
    self.signature_method ~= 'RSA-SHA1')
  then
    return error('Unsupported signature method: ' .. self.signature_method)
  end
  self.version = opts.version or '1.0'
  self.nonce_size = opts.nonce_size or 32
  self.authorize_callback = opts.authorize_callback or nil
  self.headers = opts.customHeaders or {['Accept']='*/*', ['Connection'] ='close', ['User-Agent'] = 'Luvit authentication'}
  self.clientOptions = {requestTokenHttpMethod='POST', accessTokenHttpMethod='POST', followRedirects=true}
end

function OAuth:setClientOptions(options)
  if type(options) ~= 'table' then
    return error('Options should be table value')
  end

  for key, value in pairs(options) do
    if self.clientOptions[key] ~= nil then
      self.clientOptions[key] = value
    end
  end
end

function OAuth:getOAuthRequestToken (extraParams, callback)
  if type(extraParams) == 'function' then
    callback = extraParams
    extraParams = {}
  end

  -- callbacks are related to 1.0A
  extraParams['oauth_callback'] = self.authorize_callback

  local opts = {
    method = self.clientOptions.requestTokenHttpMethod,
    extraParams = extraParams
  }

  self:request(self.requestUrl, opts, function (err, data, resp)
    if err then return callback(err) end

    local results = qs.parse(data)
    local oauth_token = results['oauth_token']
    local oauth_token_secret = results['oauth_token_secret']
    callback(nil, oauth_token, oauth_token_secret, results)
  end)
end

function OAuth:getOAuthAccessToken (oauth_token, oauth_token_secret, oauth_verifier, callback)
  local extraParams = {}
  if type(oauth_verifier) == 'function' then
    callback = oauth_verifier
  else
    extraParams.oauth_verifier = oauthEncode(oauth_verifier)
  end

  local opts = {
    method = self.clientOptions.accessTokenHttpMethod,
    extraParams = extraParams,
    oauth_token = oauth_token,
    oauth_token_secret = oauth_token_secret
  }

  self:request(self.accessUrl, opts, function (err, data, resp)
    if err then return callback(err) end

    local results = qs.parse(data)
    local oauth_access_token = results['oauth_token']
    local oauth_access_token_secret = results['oauth_token_secret']
    callback(nil, oauth_access_token, oauth_access_token_secret, results)
  end)
end

function OAuth:request (url, opts, callback)
  if not url or type(url) ~= 'string' then
    return error('Request url is required and should be a String value')
  end

  if type(opts) ~= 'table' then
    return error('Options should be a Table value')
  end

  if not opts.method then
    return error('Options should have required method field, e.g. GET, POST etc.')
  end

  if type(callback) ~= 'function' then
    return error('Callback function is required')
  end

  opts = opts or {}

  local parsedURL = URL.parse(url)
  if parsedURL.protocol == 'http' and not parsedURL.port then parsedURL.port = 80 end
  if parsedURL.protocol == 'https' and not parsedURL.port then parsedURL.port = 443 end

  local method = opts.method:upper() or 'GET'

  opts.method = method
  opts.extraParams = opts.extraParams or {}

  local orderedParams, signature = self:_prepareParams(opts.oauth_token, opts.oauth_token_secret, method, parsedURL, opts.extraParams)
  local authHeaders = self:_buildAuthorizationHeaders(orderedParams, signature)

  local headers = {}

  headers['Authorization'] = authHeaders
  headers['Host'] = parsedURL.host

  for key, value in pairs(self.headers) do
    headers[key] = value
  end

  for key, value in pairs(opts.extraParams) do
    if type(key) == 'string' and key:match('^oauth_') then
      opts.extraParams[key] = nil
    end
  end

  local path
  if not parsedURL.pathname or parsedURL.pathname == '' then path = '/' end
  if parsedURL.query and parsedURL.query ~= '' then
    path = parsedURL.pathname .. '?' .. parsedURL.query
  else
    path = parsedURL.pathname
  end

  if (method == 'POST' or method == 'PUT') and (opts.post_body == nil and opts.extraParams ~= nil) then
    opts.post_body = h.stringify(opts.extraParams)
  end

  if opts.post_body then
    headers['Content-Length'] = #opts.post_body
  else
    headers['Content-Length'] = 0
  end

  headers['Content-Type'] = opts.post_content_type or 'application/x-www-form-urlencoded'

  local allowEarlyClose = h.isAnEarlyCloseHost(parsedURL.hostname)
  local data = ''
  local callbackCalled = false
  local function passBackControl (response)
    if callbackCalled then return end

    callbackCalled = true
    if response.statusCode >= 200 and response.statusCode <= 299 then
      callback(nil, data, response)
    else
      if (response.statusCode == 301 or response.statusCode == 302) and self.clientOptions.followRedirects and response.headers and response.headers.location then
        self:request(url, opts, callback)
      else
        callback({statusCode = response.statusCode, data = data}, data, response)
      end
    end
  end
  local request = self:_createClient(parsedURL.port, parsedURL.hostname, method, path, headers, parsedURL.protocol)
  request:on('response', function (response)
    response:on('data', function (chunk)
      data = data .. chunk
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
  if (method == 'POST' or method == 'PUT') and opts.post_body ~= nil and opts.post_body ~= '' then
    request:write(opts.post_body)
  end
  request:done()
end

function OAuth:_prepareParams (oauth_token, oauth_token_secret, method, parsedURL, extraParams)
  local oauthParams = {
    oauth_consumer_key = self.consumer_key,
    oauth_nonce = generateNonce(self.nonce_size),
    oauth_signature_method = self.signature_method,
    oauth_timestamp = generateTimestamp(),
    oauth_version = self.version
  }

  if oauth_token then oauthParams['oauth_token'] = oauth_token end

  if extraParams and type(extraParams) == 'table' then
    for key, value in pairs(extraParams) do
      oauthParams[key] = value
    end
  end

  if parsedURL.query then
    local extraParameters = qs.parse(parsedURL.query)
    for key, value in pairs(extraParameters) do
      if type(value) == 'table' then
        for key2, value2 in pairs(value) do
          oauthParams[key .. '[' .. key2 .. ']'] = value2
        end
      else
        oauthParams[key] = value
      end
    end
  end

  local normalizedString, orderedParams = self:_normaliseRequestParams(oauthParams)
  local signature = self:_getSignature(method, self:_normalizeUrl(parsedURL), normalizedString, oauth_token_secret)

  return orderedParams, signature
end

function OAuth:_normalizeUrl (parsedURL)
  local port = ''
  if parsedURL.port then
    if (parsedURL.protocol == 'http' and parsedURL.port ~= 80) or (parsedURL.protocol == 'https' and parsedURL.port ~= 443) then
      port = ':' + parsedURL.port
    end
  end

  if not parsedURL.pathname or parsedURL.pathname == '' then parsedURL.pathname = '/' end

  return parsedURL.protocol .. '://' .. parsedURL.hostname .. port .. parsedURL.pathname
end

function OAuth:_normaliseRequestParams (arguments)
  -- oauth-encode each key and value, and get them set up for a Lua table sort.
  local keys_and_values = {}

  for key, val in pairs(arguments) do
    table.insert(keys_and_values, {
      key = oauthEncode(key),
      val = oauthEncode(tostring(val))
    })
  end

  -- sort by key first, then value
  table.sort(keys_and_values, function (a, b)
    if a.key < b.key then
      return true
    elseif a.key > b.key then
      return false
    else
      return a.val < b.val
    end
  end)

  -- now combine key and value into key=value
  local key_value_pairs = {}
  for _, rec in pairs(keys_and_values) do
    table.insert(key_value_pairs, rec.key .. '=' .. rec.val)
  end

  return table.concat(key_value_pairs, '&'), keys_and_values
end

function OAuth:_getSignature (method, url, params, oauth_token_secret)
  oauth_token_secret = oauth_token_secret or ''

  local signatureBase = method .. '&' .. oauthEncode(url) .. '&' .. oauthEncode(params)
  local signatureKey = oauthEncode(self.consumer_secret) .. '&' .. oauthEncode(oauth_token_secret)

  local hash = ''
  if self.signature_method == 'PLAINTEXT' then
    hash = signatureKey
  elseif self.signature_method == 'RSA-SHA1' then
    local privateKey = oauthEncode(self.consumer_secret)
    hash = crypto.sign('sha1', signatureBase, privateKey)
    hash = base64Encode(hash)
  else
    hash = crypto.hmac.digest('sha1', signatureBase, signatureKey, true)
    hash = base64Encode(hash)
  end

  return hash
end

function OAuth:_buildAuthorizationHeaders (oauthParams, signature)
  local oauth_headers = {}
  local first_header = true

  for _, rec in pairs(oauthParams) do
    if rec.key:match('^oauth_') then
      if first_header then
        rec.key = 'OAuth ' .. rec.key
        first_header = false
      end
      table.insert(oauth_headers, rec.key .. '=\"' .. oauthEncode(rec.val) .. '\"')
    end
  end

  table.insert(oauth_headers, 'oauth_signature=\"' .. oauthEncode(signature) .. '\"')
  oauth_headers = table.concat(oauth_headers, ',')

  return oauth_headers
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

-- shorteners
function OAuth:get(url, opts, callback)
  opts, callback = self:_shortenerValidator('GET', opts, callback)
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
