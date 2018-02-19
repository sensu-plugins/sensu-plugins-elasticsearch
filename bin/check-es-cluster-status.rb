#! /usr/bin/env ruby
#
#  check-es-cluster-status
#
# DESCRIPTION:
#   This plugin checks the ElasticSearch cluster status, using its API.
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
#   #YELLOW
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

#
# ES Cluster Status
#
class ESClusterStatus < Sensu::Plugin::Check::CLI
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

  option :master_only,
         description: 'Use master Elasticsearch server only',
         short: '-m',
         long: '--master-only',
         default: false

  option :timeout,
         description: 'Sets the connection timeout for REST client',
         short: '-t SECS',
         long: '--timeout SECS',
         proc: proc(&:to_i),
         default: 30

  option :status_timeout,
         description: 'Sets the time to wait for the cluster status to be green',
         short: '-T SECS',
         long: '--status_timeout SECS',
         proc: proc(&:to_i)

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

  option :cert_file,
         description: 'Cert file to use',
         short: '-c CERT_FILE',
         long: '--cert-file CERT_FILE'

  option :alert_status,
         description: 'Only alert when status matches given RED/YELLOW/GREEN or if blank all statuses',
         long: '--alert-status STATUS',
         default: '',
         in: ['RED', 'YELLOW', 'GREEN', '']

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

    r = if config[:cert_file]
          RestClient::Resource.new("#{protocol}://#{config[:host]}:#{config[:port]}#{resource}",
                                   ssl_ca_file: config[:cert_file].to_s,
                                   timeout: config[:timeout],
                                   headers: headers)
        else
          RestClient::Resource.new("#{protocol}://#{config[:host]}:#{config[:port]}#{resource}",
                                   timeout: config[:timeout],
                                   headers: headers)
        end
    JSON.parse(r.get)
  rescue Errno::ECONNREFUSED
    critical 'Connection refused'
  rescue RestClient::RequestTimeout
    critical 'Connection timed out'
  rescue RestClient::ServiceUnavailable
    critical 'Service is unavailable'
  rescue Errno::ECONNRESET
    critical 'Connection reset by peer'
  end

  def acquire_es_version
    info = get_es_resource('/')
    info['version']['number']
  end

  def master?
    if Gem::Version.new(acquire_es_version) >= Gem::Version.new('1.0.0')
      master = get_es_resource('/_cluster/state/master_node')['master_node']
      local = get_es_resource('/_nodes/_local')
    else
      master = get_es_resource('/_cluster/state?filter_routing_table=true&filter_metadata=true&filter_indices=true')['master_node']
      local = get_es_resource('/_cluster/nodes/_local')
    end
    local['nodes'].keys.first == master
  end

  def acquire_status
    health = if config[:status_timeout]
               get_es_resource("/_cluster/health?wait_for_status=green&timeout=#{config[:status_timeout]}s")
             else
               get_es_resource('/_cluster/health')
             end
    health['status'].downcase
  end

  def run
    if !config[:master_only] || master?
      case acquire_status
      when 'green'
        ok 'Cluster is green'
      when 'yellow'
        if ['YELLOW', ''].include? config[:alert_status]
          warning 'Cluster state is Yellow'
        else
          ok 'Not alerting on yellow'
        end
      when 'red'
        if ['RED', ''].include? config[:alert_status]
          critical 'Cluster state is Red'
        else
          ok 'Not alerting on red'
        end
      end
    else
      ok 'Not the master'
    end
  end
end
