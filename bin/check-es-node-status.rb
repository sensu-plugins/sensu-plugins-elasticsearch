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

class ESNodeStatus < Sensu::Plugin::Check::CLI
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

  def get_es_resource(resource)
    r = RestClient::Resource.new("http://#{config[:host]}:#{config[:port]}#{resource}", timeout: config[:timeout])
    JSON.parse(r.get)
  rescue Errno::ECONNREFUSED
    critical 'Connection refused'
  rescue RestClient::RequestTimeout
    critical 'Connection timed out'
  rescue Errno::ECONNRESET
    critical 'Connection reset by peer'
  end

  def acquire_status
    health = get_es_resource('/')
    health['status'].to_i
  end

  def run
    node_status = acquire_status

    if node_status == 200
      ok "Alive #{(node_status)}"
    else
      critical "Dead (#{node_status})"
    end
  end
end
