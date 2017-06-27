#! /usr/bin/env ruby
#
# Checks ElasticSearch shard allocation setting status
# ===
#
# DESCRIPTION:
#   Checks the ElasticSearch shard allocation persistent and transient settings
#   and will return status based on a difference in those settings.
#
# OUTPUT:
#   plain-text
#
# PLATFORMS:
#   Linux
#
# DEPENDENCIES:
#   gem: sensu-plugin
#   gem: rest-client
#
# USAGE:
#
# NOTES:
#
# LICENSE:
#   Copyright 2014 Yieldbot, Inc  <devops@yieldbot.com>
#   Released under the same terms as Sensu (the MIT license); see LICENSE
#   for details.
#

require 'sensu-plugin/check/cli'
require 'rest-client'
require 'json'
require 'base64'

#
# == Elastic Search Shard Allocation Status
#
class ESShardAllocationStatus < Sensu::Plugin::Check::CLI
  option :scheme,
         description: 'URI scheme',
         long: '--scheme SCHEME',
         default: 'http'

  option :server,
         description: 'Elasticsearch server',
         short: '-s SERVER',
         long: '--server SERVER',
         default: 'localhost'

  option :port,
         description: 'Port',
         short: '-p PORT',
         long: '--port PORT',
         default: '9200'

  option :allow_non_master,
         description: 'Allow check to run on non-master nodes',
         short: '-a',
         long: '--allow-non-master',
         default: false

  option :timeout,
         description: 'Sets the connection timeout for REST client',
         short: '-t SECS',
         long: '--timeout SECS',
         proc: proc(&:to_i),
         default: 45

  option :user,
         description: 'Elasticsearch User',
         short: '-u USER',
         long: '--user USER'

  option :password,
         description: 'Elasticsearch Password',
         short: '-P PASS',
         long: '--password PASS'

  def get_es_resource(resource)
    headers = {}
    if config[:user] && config[:password]
      auth = 'Basic ' + Base64.strict_encode64("#{config[:user]}:#{config[:password]}").chomp
      headers = { 'Authorization' => auth }
    end

    r = RestClient::Resource.new("#{config[:scheme]}://#{config[:server]}:#{config[:port]}#{resource}", timeout: config[:timeout], headers: headers)
    JSON.parse(r.get)
  rescue Errno::ECONNREFUSED
    warning 'Connection refused'
  rescue RestClient::RequestTimeout
    critical 'Connection timed out'
  rescue RestClient::ServiceUnavailable
    critical 'Service is unavailable'
  rescue Errno::ECONNRESET
    critical 'Connection reset by peer'
  end

  def master?
    state = get_es_resource('/_cluster/state/master_node')
    local = get_es_resource('/_nodes/_local')
    local['nodes'].keys.first == state['master_node']
  end

  def get_status(type)
    settings = get_es_resource('/_cluster/settings')
    # Get the status for the given type, or default to 'all'
    # which is the ES default
    begin
      settings[type]['cluster']['routing']['allocation']['enable'].downcase
    rescue
      'all'
    end
  end

  def run
    if config[:allow_non_master] || master?
      transient   = get_status('transient')
      persistent  = get_status('persistent')

      if transient == persistent
        ok "Persistent and transient allocation match:  #{persistent}"
      else
        critical "Persistent(#{persistent}) and transient(#{transient}) \
        shard allocation do not match."
      end
    else
      ok 'Not the master'
    end
  end
end
