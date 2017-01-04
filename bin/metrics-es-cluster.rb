#! /usr/bin/env ruby
#
#   es-cluster-metrics
#
# DESCRIPTION:
#   This plugin uses the ES API to collect metrics, producing a JSON
#   document which is outputted to STDOUT. An exit status of 0 indicates
#   the plugin has successfully collected and produced metrics.
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

  option :allow_non_master,
         description: 'Allow check to run on non-master nodes',
         short: '-a',
         long: '--allow-non-master',
         default: false

  option :enable_percolate,
         description: 'Enables percolator stats',
         short: '-o',
         long: '--enable-percolate',
         default: false

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
  end

  def master?
    state = if Gem::Version.new(acquire_es_version) >= Gem::Version.new('3.0.0')
              get_es_resource('/_cluster/state/master_node')
            else
              get_es_resource('/_cluster/state?filter_routing_table=true&filter_metadata=true&filter_indices=true')
            end
    local = if Gem::Version.new(acquire_es_version) >= Gem::Version.new('1.0.0')
              get_es_resource('/_nodes/_local')
            else
              get_es_resource('/_cluster/nodes/_local')
            end
    local['nodes'].keys.first == state['master_node']
  end

  def acquire_health
    health = get_es_resource('/_cluster/health').reject { |k, _v| %w(cluster_name timed_out).include?(k) }
    health['status'] = %w(red yellow green).index(health['status'])
    health
  end

  def acquire_document_count
    document_count = get_es_resource('/_stats/docs')
    count = document_count['_all']['total']
    if count.empty?
      return 0
    else
      return count['docs']['count']
    end
  end

  def acquire_cluster_metrics
    cluster_stats = get_es_resource('/_cluster/stats')
    cluster_metrics = Hash.new { |h, k| h[k] = {} }
    cluster_metrics['fs']['total_in_bytes'] = cluster_stats['nodes']['fs']['total_in_bytes']
    cluster_metrics['fs']['free_in_bytes'] = cluster_stats['nodes']['fs']['free_in_bytes']
    cluster_metrics['fs']['store_in_bytes'] = cluster_stats['indices']['store']['size_in_bytes']
    cluster_metrics['fs']['disk_reads'] = cluster_stats['nodes']['fs']['disk_reads']
    cluster_metrics['fs']['disk_writes'] = cluster_stats['nodes']['fs']['disk_writes']
    cluster_metrics['fs']['disk_read_size_in_bytes'] = cluster_stats['nodes']['fs']['disk_read_size_in_bytes']
    cluster_metrics['fs']['disk_write_size_in_bytes'] = cluster_stats['nodes']['fs']['disk_write_size_in_bytes']
    cluster_metrics['fielddata']['memory_size_in_bytes'] = cluster_stats['indices']['fielddata']['memory_size_in_bytes']
    cluster_metrics['fielddata']['evictions'] = cluster_stats['indices']['fielddata']['evictions']

    # Elasticsearch changed the name filter_cache to query_cache in 2.0+
    cache_name = Gem::Version.new(acquire_es_version) < Gem::Version.new('2.0.0') ? 'filter_cache' : 'query_cache'

    cluster_metrics[cache_name]['memory_size_in_bytes'] = cluster_stats['indices'][cache_name]['memory_size_in_bytes']
    cluster_metrics[cache_name]['evictions'] = cluster_stats['indices'][cache_name]['evictions']
    cluster_metrics['mem'] = cluster_stats['nodes']['jvm']['mem']

    if config[:enable_percolate]
      cluster_metrics['percolate']['total'] = cluster_stats['indices']['percolate']['total']
      cluster_metrics['percolate']['time_in_millis'] = cluster_stats['indices']['percolate']['time_in_millis']
      cluster_metrics['percolate']['queries'] = cluster_stats['indices']['percolate']['queries']
    end
    cluster_metrics
  end

  def acquire_allocation_status
    cluster_config = get_es_resource('/_cluster/settings')
    transient_settings = cluster_config['transient']
    if transient_settings.empty?
      return nil
    else
      return %w(none new_primaries primaries all).index(transient_settings['cluster']['routing']['allocation']['enable'])
    end
  end

  def run
    if config[:allow_non_master] || master?
      acquire_health.each do |k, v|
        output(config[:scheme] + '.' + k, v)
      end
      acquire_cluster_metrics.each do |cluster_metric|
        cluster_metric[1].each do |k, v|
          output(config[:scheme] + '.' + cluster_metric[0] + '.' + k, v)
        end
      end
      output(config[:scheme] + '.document_count', acquire_document_count)
      output(config[:scheme] + '.allocation_status', acquire_allocation_status) unless acquire_allocation_status.nil?
    end
    ok
  end
end
