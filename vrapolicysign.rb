#!/opt/puppetlabs/puppet/bin/ruby
 
require 'openssl'
require 'net/http'
require 'uri'
require 'json'
require 'openssl'
require 'yaml'


configfile = "/etc/puppetlabs/puppet/vrapolicyconfig.yaml"
logfile = "/etc/puppetlabs/puppet/ssl/vrapolicylog.log"

# Load vRealize Automation connection information from config file
CONFIG = YAML.load_file(configfile)

# Log output to a json file
def jsonlogger(status,certname,jsonuuid)
  tempHash = {
    "status" => status,
    "certname" => certname,
    "uuid" => jsonuuid
  }
  File.open(logfile,"a") do |f|
    f.puts(tempHash.to_json)
  end
end

# Parse the CSR for the machine uuid
def parse_extensions(extension_request)
  extension_request_hash = {}
  extension_request.each do |extension|
    extension_request_hash[extension.value[0].value] = extension.value[1].value
  end
  return extension_request_hash
end


$csr = $stdin.read
$extensions_hash = {}
request = OpenSSL::X509::Request.new $csr
 
request.attributes.each do |attribute|
  attr = OpenSSL::X509::Attribute.new attribute
  test = attr.oid
  if test == "extReq"
    $extensions_hash = parse_extensions(attr.value.value.first.value)
  end
end

$uuid = $extensions_hash['1.3.6.1.4.1.34380.1.1.1'].strip().chomp.to_s.gsub('$', '')

# Get a vRealize Automation authentication token
def gettoken(url,username,password,tenant)
  url1 = "#{url}/identity/api/tokens"
  uri = URI.parse(url1)
  request = Net::HTTP::Post.new(uri)
  request.content_type = "application/json"
  request["Accept"] = "application/json"
  request.body = JSON.dump({
    "username" => username,
    "password" => password,
    "tenant" => tenant
  })

  req_options = {
    use_ssl: uri.scheme == "https",
    verify_mode: OpenSSL::SSL::VERIFY_NONE,
  }

  response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
    http.request(request)
  end

  token_output = response.body
  token_json = JSON.parse(token_output)
  vra_token = token_json["id"]
  return vra_token
  end

# Query vRealize Automation for the machine uuid
def queryvra(url,uuid,token)
  uri = URI.parse("#{url}/catalog-service/api/consumer/resources?%24filter=providerBinding/bindingId%20eq%20%27#{uuid}%27")
  request = Net::HTTP::Get.new(uri)
  request.content_type = "application/json"
  request["Authorization"] = "Bearer #{token}"

  req_options = {
    use_ssl: uri.scheme == "https",
    verify_mode: OpenSSL::SSL::VERIFY_NONE,
  }

  response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
    http.request(request)
  end

  json_output = response.body
  vra_item = JSON.parse(json_output)
  vra_exists = vra_item['metadata']['totalElements']
  return vra_exists
end


$certname = ARGV[0]

# Loop through each connection
CONFIG.each_value do |item|
  tmptoken = gettoken(item['url'],item['username'],item['password'],item['tenant'])
  tmptoken = tmptoken.to_s
  status = queryvra(item['url'],$uuid,tmptoken)
  if status.to_s == "1"
    jsonlogger("success",$certname,$uuid)
    exit 0
  end
end


jsonlogger("failure",$certname,$uuid)
exit 1
