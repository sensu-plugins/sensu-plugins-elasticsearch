#! /usr/bin/env ruby
#
#   es-cluster-metrics
#
# DESCRIPTION:
#   This plugin uses the ES API to collect metrics, producing a JSON
#   document which is outputted to STDOUT. An exit status of 0 indicates
#   the plugin has successfully collected and produced.
#
# OUTPUT:
#   metric data
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
#   Copyright 2011 Sonian, Inc <chefs@sonian.net>
#   Released under the same terms as Sensu (the MIT license); see LICENSE
#   for details.
#

require 'sensu-plugin/metric/cli'
require 'rest-client'
require 'json'
require 'base64'

#
# ES Cluster Metrics
#
class ESClusterMetrics < Sensu::Plugin::Metric::CLI::Graphite
  option :scheme,
         description: 'Metric naming scheme, text to prepend to metric',
         short: '-s SCHEME',
         long: '--scheme SCHEME',
         default: "#{Socket.gethostname}.elasticsearch.cluster"

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

  def acquire_es_version
    info = get_es_resource('/')
    info['version']['number']
  end

  def get_es_resource(resource)
    headers = {}
    if config[:user] && config[:password]
      auth = 'Basic ' + Base64.encode64("#{config[:user]}:#{config[:password]}").chomp
      headers = { 'Authorization' => auth }
    end
    r = RestClient::Resource.new("http://#{config[:host]}:#{config[:port]}#{resource}", timeout: config[:timeout], headers: headers)
    JSON.parse(r.get)
  rescue Errno::ECONNREFUSED
    warning 'Connection refused'
  rescue RestClient::RequestTimeout
    warning 'Connection timed out'
  end

  def master?
    state = get_es_resource('/_cluster/state?filter_routing_table=true&filter_metadata=true&filter_indices=true')
    if Gem::Version.new(acquire_es_version) >= Gem::Version.new('1.0.0')
      local = get_es_resource('/_nodes/_local')
    else
      local = get_es_resource('/_cluster/nodes/_local')
    end
    local['nodes'].keys.first == state['master_node']
  end

  def acquire_health
    health = get_es_resource('/_cluster/health').reject { |k, _v| %w(cluster_name timed_out).include?(k) }
    health['status'] = %w(red yellow green).index(health['status'])
    health
  end

  def acquire_document_count
    document_count = get_es_resource('/_count?q=*:*')
    document_count['count']
  end

  def run
    if master?
      acquire_health.each do |k, v|
        output(config[:scheme] + '.' + k, v)
      end
      output(config[:scheme] + '.document_count', acquire_document_count)
    end
    ok
  end
end
