#! /usr/bin/env ruby
#
#  check-es-node-status
#
# DESCRIPTION:
#   This plugin checks the ElasticSearch node status, using its API.
#   Works with ES 0.9x and ES 1.x
#
# OUTPUT:
#   plain text
#
# PLATFORMS:
#   Linux
#
# DEPENDENCIES:
#   gem: sensu-plugin
#   gem: rest-client
#
# USAGE:
#   check-es-node-status --help
#
# NOTES:
#
# LICENSE:
#   Copyright 2012 Sonian, Inc <chefs@sonian.net>
#   Released under the same terms as Sensu (the MIT license); see LICENSE
#   for details.
#

require 'sensu-plugin/check/cli'
require 'rest-client'
require 'json'
require 'base64'
require 'pp'

class ESCircuitBreaker < Sensu::Plugin::Check::CLI
  option :host,
         description: 'Elasticsearch host',
         short: '-h HOST',
         long: '--host HOST',
         default: 'localhost'

  option :port,
         description: 'Elasticsearch port',
         short: '-p PORT',
         long: '--port PORT',
         proc: proc(&:to_i),
         default: 9200

  option :timeout,
         description: 'Sets the connection timeout for REST client',
         short: '-t SECS',
         long: '--timeout SECS',
         proc: proc(&:to_i),
         default: 30

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
      auth = 'Basic ' + Base64.encode64("#{config[:user]}:#{config[:password]}").chomp
      headers = { 'Authorization' => auth }
    end
    r = RestClient::Resource.new("http://#{config[:host]}:#{config[:port]}#{resource}", timeout: config[:timeout], headers: headers)
    JSON.parse(r.get)
  rescue Errno::ECONNREFUSED
    critical 'Connection refused'
  rescue RestClient::RequestTimeout
    critical 'Connection timed out'
  rescue Errno::ECONNRESET
    critical 'Connection reset by peer'
  end

  def breaker_status
    breakers = {}
    status = get_es_resource('/_nodes/stats/breaker')
    status['nodes'].each_pair do |_node, stat|
      host = stat['host']
      breakers[host] = {}
      breakers[host]['breakers'] = []
      stat.each_pair do |key, val|
        if key == 'breakers'
          val.each_pair do |bk, bv|
            if bv['tripped'] != 0
              breakers[host]['breakers'] << bk
            end
          end
        end
      end
    end
    breakers
  end

  def run
    breakers = breaker_status
    tripped = false
    breakers.each_pair { |_k, v| tripped = true unless v['breakers'].empty? }
    if tripped
      critical "Circuit Breakers: #{breakers.each_pair { |k, _v| k }} trippped!"
    else
      ok 'All circuit breakers okay'
    end
  end
end
