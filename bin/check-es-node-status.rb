#! /usr/bin/env ruby
#
#  check-es-node-status
#
# DESCRIPTION:
#   This plugin checks the ElasticSearch node status, using its API.
#   Works with ES 0.9x, ES 1.x, and ES 2.x
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

  option :user,
         description: 'Elasticsearch User',
         short: '-u USER',
         long: '--user USER'

  option :password,
         description: 'Elasticsearch Password',
         short: '-P PASS',
         long: '--password PASS'

  option :https,
         description: 'Enables HTTPS',
         short: '-e',
         long: '--https'

  option :all,
         description: 'Check all nodes in the ES cluster',
         short: '-a',
         long: '--all',
         default: false

  def get_es_resource(resource)
    headers = {}
    if config[:user] && config[:password]
      auth = 'Basic ' + Base64.strict_encode64("#{config[:user]}:#{config[:password]}").chomp
      headers = { 'Authorization' => auth }
    end

    protocol = if config[:https]
                 'https'
               else
                 'http'
               end

    r = if config[:cert]
          RestClient::Resource.new("#{protocol}://#{config[:host]}:#{config[:port]}#{resource}",
                                   ssl_ca_file: config[:cert].to_s,
                                   timeout: config[:timeout],
                                   headers: headers)
        else
          RestClient::Resource.new("#{protocol}://#{config[:host]}:#{config[:port]}#{resource}",
                                   timeout: config[:timeout],
                                   headers: headers)
        end
    r.get
  rescue Errno::ECONNREFUSED
    critical 'Connection refused'
  rescue RestClient::RequestTimeout
    critical 'Connection timed out'
  rescue Errno::ECONNRESET
    critical 'Connection reset by peer'
  end

  def acquire_status
    status = get_es_resource('/_nodes/stats')
    status
  end

  def run
    stats = acquire_status

    if stats.code == 200
      if config[:all]
        total = stats['_nodes']['total']
        successful = stats['_nodes']['successful']
        if total == successful
          ok 'Alive - all nodes'
        else
          critical 'Dead - one or more nodes'
        end
      else
        ok "Alive #{stats.code}"
      end
    else
      critical "Dead (#{stats.code})"
    end
  end
end
