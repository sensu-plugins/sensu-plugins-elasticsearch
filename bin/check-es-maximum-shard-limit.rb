#! /usr/bin/env ruby
#
# Checks to see if there are too many shards in the cluster
# ===
#
# DESCRIPTION:
#   Checks to see if the number of shards in the Elasticsearch cluster
#   breaches a limit based on the number of nodes in the cluster and
#   a configurable limit per node
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
#   This check will check the limit across the cluster, it does not check the
#   shard limit on a node by node basis
#
# LICENSE:
#   Thomas Riley
#   Released under the same terms as Sensu (the MIT license); see LICENSE
#   for details.
#

require 'sensu-plugin/check/cli'
require 'rest-client'
require 'json'
require 'base64'

#
# == Elastic Search Shard Limit Status
#
class ESShardMaximumLimit < Sensu::Plugin::Check::CLI
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

  option :node_limit,
         description: 'Limit of shards per node',
         short: '-l LIMIT',
         long: '--limit LIMIT',
         default: 1000

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

  def shard_count
    cluster_health = get_es_resource('/_cluster/health')
    cluster_health['active_shards']
  end

  def node_count
    cluster_health = get_es_resource('/_cluster/health')
    cluster_health['number_of_nodes']
  end

  def run
    if config[:allow_non_master] || master?
      shard_count = shard_count()
      node_count = node_count()
      if shard_count > (node_count * config[:node_limit])
        critical "Shard count has breached the limit (#{shard_count}/#{node_count * config[:node_limit]})"
      elsif (shard_count >= (node_count * (config[:node_limit] - 100))) && (shard_count <= (node_count * config[:node_limit]))
        warning "Shard count is near the limit (#{shard_count}/#{node_count * config[:node_limit]})"
      elsif shard_count < (node_count * (config[:node_limit] - 100))
        ok "Shard count is OK (#{shard_count}/#{node_count * config[:node_limit]})"
      end
    else
      ok 'Not the master'
    end
  end
end
