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
require 'time'
require 'aws_es_transport'
require 'sensu-plugins-elasticsearch'

#
# ES Query Exists
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

  option :id,
         description: 'ID of the ElasticSearch document to check for existence',
         long: '--id ID',
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

  option :headers,
         description: 'A comma separated list of headers to pass to elasticsearch http client',
         short: '-H headers',
         long: '--headers headers',
         default: 'Content-Type: application/json'

  option :timeout,
         description: 'Elasticsearch query timeout in seconds',
         short: '-t TIMEOUT',
         long: '--timeout TIMEOUT',
         proc: proc(&:to_i),
         default: 30

  option :warn,
         short: '-w',
         long: '--warn',
         description: 'Warn instead of critical',
         boolean: true,
         default: false

  option :invert,
         long: '--invert',
         description: 'Invert status',
         boolean: true,
         default: false

  def run
    if client.exists?(build_request_options)
      if config[:invert]
        if config[:warn]
          warning
        else
          critical
        end
      else
        ok
      end
    elsif config[:invert]
      ok
    elsif config[:warn]
      warning
    else
      critical
    end
  end
end
