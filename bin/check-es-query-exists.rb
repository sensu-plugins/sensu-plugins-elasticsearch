#! /usr/bin/env ruby
#
#   check-es-query-exists
#
# DESCRIPTION:
#   This plugin checks an ElasticSearch query that documents exist.
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
#       "docker.args:special AND *specialstring* AND _exists_:key.name"
#       at the host elasticsearch.service.consul and port 9200 for the past 3 minutes
#       will go critical if there are NO results for that period.
#       This check is to ensure that events are happening at all.
#   check-es-query-exists.rb -h elasticsearch.service.consul
#           -q "docker.args:special AND *specialstring* AND _exists_:key.name" --invert
#           --types special_type -d 'logging-%Y.%m.%d' --minutes-previous 3 -p 9200
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
require 'sensu-plugins-elasticsearch'

#
# ES Heap
#
class ESQueryExists < Sensu::Plugin::Check::CLI
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

  option :timestamp_field,
         description: 'Field to use instead of @timestamp for query.',
         long: '--timestamp_field FIELD_NAME',
         default: '@timestamp'

  option :offset,
         description: 'Seconds before offset to end @timestamp against query.',
         long: '--offset OFFSET',
         proc: proc(&:to_i),
         default: 0

  option :minutes_previous,
         description: 'Minutes before offset to check @timestamp against query.',
         long: '--minutes-previous MINUTES_PREVIOUS',
         proc: proc(&:to_i),
         default: 0

  option :hours_previous,
         description: 'Hours before offset to check @timestamp against query.',
         long: '--hours-previous DAYS_PREVIOUS',
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

  option :shield_user,
         description: 'Shield User',
         short: '-s',
         long: '--shield-user USER'

  option :shield_password,
         description: 'Shield Password',
         short: '-d',
         long: '--shield-password PASS'

    def run # rubocop:disable all
      client.exists(build_request_options)
      ok
    rescue Elasticsearch::Transport::Transport::Errors::NotFound
      critical
    end
end
