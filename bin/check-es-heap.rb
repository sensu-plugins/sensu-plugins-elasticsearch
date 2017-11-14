#! /usr/bin/env ruby
#
#   check-es-heap
#
# DESCRIPTION:
#   This plugin checks ElasticSearch's Java heap usage using its API.
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
#   example commands
#
# NOTES:
#
# LICENSE:
#  Copyright 2012 Sonian, Inc <chefs@sonian.net>
#   Released under the same terms as Sensu (the MIT license); see LICENSE
#   for details.
#

require 'sensu-plugin/check/cli'
require 'rest-client'
require 'json'
require 'base64'

#
# ES Heap
#
class ESHeap < Sensu::Plugin::Check::CLI
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

  option :warn,
         short: '-w N',
         long: '--warn N',
         description: 'Heap used in bytes WARNING threshold',
         proc: proc(&:to_i),
         default: 0

  option :timeout,
         description: 'Sets the connection timeout for REST client',
         short: '-t SECS',
         long: '--timeout SECS',
         proc: proc(&:to_i),
         default: 30

  option :crit,
         short: '-c N',
         long: '--crit N',
         description: 'Heap used in bytes CRITICAL threshold',
         proc: proc(&:to_i),
         default: 0

  option :percentage,
         short: '-P',
         long: '--percentage',
         description: 'Use the WARNING and CRITICAL threshold numbers as percentage indicators of the total heap available',
         default: false

  option :user,
         description: 'Elasticsearch User',
         short: '-u USER',
         long: '--user USER'

  option :password,
         description: 'Elasticsearch Password',
         short: '-W PASS',
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

  def acquire_es_version
    info = acquire_es_resource('/')
    info['version']['number']
  end

  def acquire_es_resource(resource)
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

    r = RestClient::Resource.new("#{protocol}://#{config[:host]}:#{config[:port]}#{resource}", timeout: config[:timeout], headers: headers)
    JSON.parse(r.get)
  rescue Errno::ECONNREFUSED
    warning 'Connection refused'
  rescue RestClient::RequestTimeout
    warning 'Connection timed out'
  rescue RestClient::ServiceUnavailable
    warning 'Service is unavailable'
  rescue JSON::ParserError
    warning 'Elasticsearch API returned invalid JSON'
  end

  def acquire_stats
    if Gem::Version.new(acquire_es_version) >= Gem::Version.new('1.0.0')
      if config[:all]
        acquire_es_resource('/_nodes/stats')
      else
        acquire_es_resource('/_nodes/_local/stats')
      end
    elsif config[:all]
      acquire_es_resource('/_cluster/nodes/stats')
    else
      acquire_es_resource('/_cluster/nodes/_local/stats')
    end
  end

  def acquire_heap_data(node)
    return node['jvm']['mem']['heap_used_in_bytes'], node['jvm']['mem']['heap_max_in_bytes']
  rescue
    warning 'Failed to obtain heap used in bytes'
  end

  def acquire_heap_usage(heap_used, heap_max, node_name)
    if config[:percentage]
      heap_usage = ((100 * heap_used) / heap_max).to_i
      output = if config[:all]
                 "Node #{node_name}: Heap used in bytes #{heap_used} (#{heap_usage}% full)\n"
               else
                 "Heap used in bytes #{heap_used} (#{heap_usage}% full)"
               end
    else
      heap_usage = heap_used
      output = config[:all] ? "Node #{node_name}: Heap used in bytes #{heap_used}\n" : "Heap used in bytes #{heap_used}"
    end
    [heap_usage, output]
  end

  def run
    stats = acquire_stats
    status_w = false
    status_c = false
    w_msg = ''
    c_msg = ''
    msg = ''

    # Check all the nodes in the cluster, alert if any of the nodes have heap usage above thresholds
    stats['nodes'].each do |_, node|
      heap_used, heap_max = acquire_heap_data(node)
      heap_usage, output = acquire_heap_usage(heap_used, heap_max, node['name'])
      if heap_usage >= config[:crit]
        c_msg += output
        status_c = true
      elsif heap_usage >= config[:warn]
        w_msg += output
        status_w = true
      elsif !config[:all]
        msg += output
      end
    end

    if status_c
      message c_msg
      critical
    elsif status_w
      message w_msg
      warning
    else
      message msg
      ok
    end
  end
end
