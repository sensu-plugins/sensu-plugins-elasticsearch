#! /usr/bin/env ruby
#
#   es-node-metrics
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
# ES Node Metrics
#
class ESMetrics < Sensu::Plugin::Metric::CLI::Graphite
  option :scheme,
         description: 'Metric naming scheme, text to prepend to queue_name.metric',
         short: '-s SCHEME',
         long: '--scheme SCHEME',
         default: "#{Socket.gethostname}.elasticsearch"

  option :host,
         description: 'Elasticsearch server host.',
         short: '-h HOST',
         long: '--host HOST',
         default: 'localhost'

  option :port,
         description: 'Elasticsearch port',
         short: '-p PORT',
         long: '--port PORT',
         proc: proc(&:to_i),
         default: 9200

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
         long: '--cert CERT_FILE'

  def acquire_es_version
    info = get_es_resource('/')
    info['version']['number']
  end

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
    ::JSON.parse(r.get)
  rescue Errno::ECONNREFUSED
    warning 'Connection refused'
  rescue RestClient::RequestTimeout
    warning 'Connection timed out'
  end

  def run
    es_version = Gem::Version.new(acquire_es_version)

    if es_version >= Gem::Version.new('1.0.0')
      ln = get_es_resource('/_nodes/_local')
      stats = get_es_resource('/_nodes/_local/stats')
    else
      ln = get_es_resource('/_cluster/nodes/_local')
      stats = get_es_resource('/_cluster/nodes/_local/stats')
    end

    timestamp = Time.now.to_i
    node = stats['nodes'].values.first
    node['jvm']['mem']['heap_max_in_bytes'] = ln['nodes'].values.first['jvm']['mem']['heap_max_in_bytes']
    metrics = {}
    metrics['os.load_average'] = if es_version >= Gem::Version.new('2.0.0')
                                   node['os']['load_average']
                                 else
                                   node['os']['load_average'][0]
                                 end
    metrics['os.mem.free_in_bytes'] = node['os']['mem']['free_in_bytes']
    metrics['process.mem.resident_in_bytes'] = node['process']['mem']['resident_in_bytes']
    metrics['jvm.mem.heap_used_in_bytes'] = node['jvm']['mem']['heap_used_in_bytes']
    metrics['jvm.mem.non_heap_used_in_bytes'] = node['jvm']['mem']['non_heap_used_in_bytes']
    metrics['jvm.gc.collection_time_in_millis'] = node['jvm']['gc']['collection_time_in_millis']
    metrics.each do |k, v|
      output([config[:scheme], k].join('.'), v, timestamp)
    end
    ok
  end
end
