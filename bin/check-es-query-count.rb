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

require_relative 'sensu-plugins-elasticsearch'

#
# ES Heap
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

  option :types,
         description: 'Elasticsearch types to limit searches to, comma separated list.',
         long: '--types TYPES'

  option :minutes_previous,
         description: 'Minutes before now to check @timestamp against query.',
         long: '--minutes-previous MINUTES_PREVIOUS',
         proc: proc(&:to_i),
         default: 0

  option :hours_previous,
         description: 'Hours before now to check @timestamp against query.',
         long: '--hours-previous HOURS_PREVIOUS',
         proc: proc(&:to_i),
         default: 0

  option :days_previous,
         description: 'Days before now to check @timestamp against query.',
         long: '--days-previous DAYS_PREVIOUS',
         proc: proc(&:to_i),
         default: 0

  option :weeks_previous,
         description: 'Weeks before now to check @timestamp against query.',
         long: '--weeks-previous WEEKS_PREVIOUS',
         proc: proc(&:to_i),
         default: 0

  option :months_previous,
         description: 'Months before now to check @timestamp against query.',
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
         long: '--scheme SCHEME',
         default: 'https'

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

  def run
    response = client.count(build_request_options)
    if config[:invert]
      if response['count'] < config[:crit]
        critical 'Query count was below critical threshold'
      elsif response['count'] < config[:warn]
        warning 'Query count was below warning threshold'
      else
        ok
      end
    else
      if response['count'] > config[:crit]
        critical 'Query count was above critical threshold'
      elsif response['count'] > config[:warn]
        warning 'Query count was above warning threshold'
      else
        ok
      end
    end
rescue Elasticsearch::Transport::Transport::Errors::NotFound
  if config[:invert]
    if response['count'] < config[:crit]
      critical 'Query count was below critical threshold'
    elsif response['count'] < config[:warn]
      warning 'Query count was below warning threshold'
    else
      ok
    end
  else
    ok 'No results found, count was below thresholds'
  end
  end
end
