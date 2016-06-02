#! /usr/bin/env ruby
#
#   check-es-query
#
# DESCRIPTION:
#   This plugin checks an ElasticSearch query.
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
#   This example checks that the count of special_type logs matching a query of
#       anything (*) at the host elasticsearch.service.consul for the past 90 minutes
#       will warn if there are under 100 and go critical if the result count is below 1
#       (The invert flag warns if counts are _below_ the critical and warning values)
#   check-es-query-count.rb -h elasticsearch.service.consul -q "*" --invert
#           --types special_type -d 'logging-%Y.%m.%d' --minutes-previous 90 -p 9200 -c 1 -w 100
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
require 'time'
require 'uri'
require 'aws_es_transport'
require 'sensu-plugins-elasticsearch'

#
# ES Query Count
#
class ESQueryCount < Sensu::Plugin::Check::CLI
  include ElasticsearchCommon

  option :index,
         description: 'Elasticsearch indices to query.
         Comma-separated list of index names to search.
         Use `_all` or empty string to perform the operation on all indices.
         Accepts wildcards',
         short: '-i INDEX',
         long: '--indices INDEX'

  option :transport,
         long: '--transport TRANSPORT',
         description: 'Transport to use to communicate with ES. Use "AWS" for signed AWS transports.'

  option :region,
         long: '--region REGION',
         description: 'Region (necessary for AWS Transport)'

  option :types,
         description: 'Elasticsearch types to limit searches to, comma separated list.',
         long: '--types TYPES'

  option :timestamp_field,
         description: 'Field to use instead of @timestamp for query.',
         long: '--timestamp-field FIELD_NAME',
         default: '@timestamp'

  option :offset,
         description: 'Seconds before offset to end @timestamp against query.',
         long: '--offset OFFSET',
         proc: proc(&:to_i),
         default: 0

  option :ignore_unavailable,
         description: 'Ignore unavailable indices.',
         long: '--ignore-unavailable',
         boolean: true,
         default: true

  option :minutes_previous,
         description: 'Minutes before offset to check @timestamp against query.',
         long: '--minutes-previous MINUTES_PREVIOUS',
         proc: proc(&:to_i),
         default: 0

  option :hours_previous,
         description: 'Hours before offset to check @timestamp against query.',
         long: '--hours-previous HOURS_PREVIOUS',
         proc: proc(&:to_i),
         default: 0

  option :days_previous,
         description: 'Days before offset to check @timestamp against query.',
         long: '--days-previous DAYS_PREVIOUS',
         proc: proc(&:to_i),
         default: 0

  option :weeks_previous,
         description: 'Weeks before offset to check @timestamp against query.',
         long: '--weeks-previous WEEKS_PREVIOUS',
         proc: proc(&:to_i),
         default: 0

  option :months_previous,
         description: 'Months before offset to check @timestamp against query.',
         long: '--months-previous MONTHS_PREVIOUS',
         proc: proc(&:to_i),
         default: 0

  option :date_index,
         description: 'Elasticsearch time based index.
            Accepts format from http://ruby-doc.org/core-2.2.0/Time.html#method-i-strftime',
         short: '-d DATE_INDEX',
         long: '--date-index DATE_INDEX'

  option :date_repeat_daily,
         description: 'Elasticsearch date based index repeats daily.',
         long: '--repeat-daily',
         boolean: true,
         default: true

  option :date_repeat_hourly,
         description: 'Elasticsearch date based index repeats hourly.',
         long: '--repeat-hourly',
         boolean: true,
         default: false

  option :search_field,
         description: 'The Elasticsearch document field to search for your query string.',
         short: '-f FIELD',
         long: '--field FIELD',
         required: false,
         default: 'message'

  option :query,
         description: 'Elasticsearch query',
         short: '-q QUERY',
         long: '--query QUERY',
         required: true

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

  option :warn,
         short: '-w N',
         long: '--warn N',
         description: 'Result count WARNING threshold',
         proc: proc(&:to_i),
         default: 0

  option :crit,
         short: '-c N',
         long: '--crit N',
         description: 'Result count CRITICAL threshold',
         proc: proc(&:to_i),
         default: 0

  option :invert,
         long: '--invert',
         description: 'Invert thresholds',
         boolean: true

  option :kibana_url,
         long: '--kibana-url KIBANA_URL',
         description: 'Kibana URL query prefix that will be in critical / warning response output.'

  def kibana_info
    kibana_date_format = '%Y-%m-%dT%H:%M:%S.%LZ'
    unless config[:kibana_url].nil?
      index = config[:index]
      unless config[:date_index].nil?
        date_index_partition = config[:date_index].split('%')
        index = "[#{date_index_partition.first}]" \
          "#{date_index_partition[1..-1].join.sub('Y', 'YYYY').sub('y', 'YY').sub('m', 'MM').sub('d', 'DD').sub('j', 'DDDD').sub('H', 'hh')}"
      end
      end_time = Time.now.utc.to_i
      start_time = end_time
      if config[:minutes_previous] != 0
        start_time -= (config[:minutes_previous] * 60)
      end
      if config[:hours_previous] != 0
        start_time -= (config[:hours_previous] * 60 * 60)
      end
      if config[:days_previous] != 0
        start_time -= (config[:days_previous] * 60 * 60 * 24)
      end
      if config[:weeks_previous] != 0
        start_time -= (config[:weeks_previous] * 60 * 60 * 24 * 7)
      end
      if config[:months_previous] != 0
        start_time -= (config[:months_previous] * 60 * 60 * 24 * 7 * 31)
      end
      "Kibana logs: #{config[:kibana_url]}/#/discover?_g=" \
      "(refreshInterval:(display:Off,section:0,value:0),time:(from:'" \
      "#{URI.escape(Time.at(start_time).utc.strftime kibana_date_format)}',mode:absolute,to:'" \
      "#{URI.escape(Time.at(end_time).utc.strftime kibana_date_format)}'))&_a=(columns:!(_source),index:" \
      "#{URI.escape(index)},interval:auto,query:(query_string:(analyze_wildcard:!t,query:'" \
      "#{URI.escape(config[:query])}')),sort:!('@timestamp',desc))&dummy"
    end
  end

  def run
    response = client.count(build_request_options)
    if config[:invert]
      if response['count'] < config[:crit]
        critical "Query count (#{response['count']}) was below critical threshold. #{kibana_info}"
      elsif response['count'] < config[:warn]
        warning "Query count (#{response['count']}) was below warning threshold. #{kibana_info}"
      else
        ok "Query count (#{response['count']}) was ok"
      end
    elsif response['count'] > config[:crit]
      critical "Query count (#{response['count']}) was above critical threshold. #{kibana_info}"
    elsif response['count'] > config[:warn]
      warning "Query count (#{response['count']}) was above warning threshold. #{kibana_info}"
    else
      ok "Query count (#{response['count']}) was ok"
    end
  rescue Elasticsearch::Transport::Transport::Errors::NotFound
    if config[:invert]
      if response['count'] < config[:crit]
        critical "Query count (#{response['count']}) was below critical threshold. #{kibana_info}"
      elsif response['count'] < config[:warn]
        warning "Query count (#{response['count']}) was below warning threshold. #{kibana_info}"
      else
        ok "Query count (#{response['count']}) was ok"
      end
    else
      ok 'No results found, count was below thresholds'
    end
  end
end
