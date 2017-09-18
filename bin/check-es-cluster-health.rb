#! /usr/bin/env ruby
#
#   check-es-cluster-health
#
# DESCRIPTION:
#   This plugin checks the ElasticSearch cluster health and status.
#
# OUTPUT:
#   plain text
#
# PLATFORMS:
#   Linux
#
# DEPENDENCIES:
#   gem: sensu-plugin
#   gem: elasticsearch
#   gem: aws_es_transport
#
# USAGE:
#   Checks against the ElasticSearch api for cluster health using the
#     elasticsearch gem
#
# NOTES:
#
# LICENSE:
#   Brendan Gibat <brendan.gibat@gmail.com>
#   Released under the same terms as Sensu (the MIT license); see LICENSE
#   for details.
#

require 'sensu-plugin/check/cli'
require 'elasticsearch'
require 'aws_es_transport'
require 'sensu-plugins-elasticsearch'

#
# ES Cluster Health
#
class ESClusterHealth < Sensu::Plugin::Check::CLI
  include ElasticsearchCommon

  option :transport,
         long: '--transport TRANSPORT',
         description: 'Transport to use to communicate with ES. Use "AWS" for signed AWS transports.'

  option :region,
         long: '--region REGION',
         description: 'Region (necessary for AWS Transport)'

  option :host,
         description: 'Elasticsearch host',
         short: '-h HOST',
         long: '--host HOST',
         default: 'localhost'

  option :level,
         description: 'Level of detail to check returend information ("cluster", "indices", "shards").',
         short: '-l LEVEL',
         long: '--level LEVEL'

  option :local,
         description: 'Return local information, do not retrieve the state from master node.',
         long: '--local',
         boolean: true

  option :port,
         description: 'Elasticsearch port',
         short: '-p PORT',
         long: '--port PORT',
         proc: proc(&:to_i),
         default: 9200

  option :scheme,
         description: 'Elasticsearch connection scheme, defaults to https for authenticated connections',
         short: '-s SCHEME',
         long: '--scheme SCHEME'

  option :password,
         description: 'Elasticsearch connection password',
         short: '-P PASSWORD',
         long: '--password PASSWORD'

  option :user,
         description: 'Elasticsearch connection user',
         short: '-u USER',
         long: '--user USER'

  option :timeout,
         description: 'Elasticsearch query timeout in seconds',
         short: '-t TIMEOUT',
         long: '--timeout TIMEOUT',
         proc: proc(&:to_i),
         default: 30

  option :alert_status,
         description: 'Only alert when status matches given RED/YELLOW/GREEN or if blank all statuses',
         long: '--alert-status STATUS',
         default: '',
         in: ['RED', 'YELLOW', 'GREEN', '']

  def run
    options = {}
    unless config[:level].nil?
      options[:level] = config[:level]
    end
    unless config[:local].nil?
      options[:local] = config[:local]
    end
    unless config[:index].nil?
      options[:index] = config[:index]
    end
    health = client.cluster.health options
    case health['status']
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
    when 'green'
      ok
    else
      unknown "Cluster state is in an unknown health: #{health['status']}"
    end
  end
end
