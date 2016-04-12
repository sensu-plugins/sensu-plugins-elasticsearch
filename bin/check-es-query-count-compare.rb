#! /usr/bin/env ruby
#
#   check-es-query-count-compare
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
#   This example checks that the amount of 200 HTTP responses is at least
#       70% out of all HTTP responses. But you can evaluate any ruby code
#       with quries results like '(queries[0]*100/queries[1]+queries[2]).round'
#   check-es-query-count-compare.rb -h elasticsearch.service.consul --queries "http.status:200, http.status:*"
#       --action 'queries[0]*100/qeuries[1]'  --hours-previous 24 -c 70 --invert
#
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
require 'sensu-plugins-elasticsearch'

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

  option :timestamp_field,
         description: 'Field to use instead of @timestamp for query.',
         long: '--timestamp-field FIELD_NAME',
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

  option :queries,
         description: 'Comma-separated list of Elasticsearch queiries to compate.',
         short: '-q QUERIES',
         long: '--queries QUERIES',
         required: true

  option :action,
         description: 'Ruby code to evaluate for queries responses.
           Example: (queries[0]+queries[1]/queries[2]).round(2)',
         short: '-a ACTION',
         long: '--action ACTION',
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


  def evaluate_action(action, queries)
    eval(action)
  end

  def run
    # Parse comma separated list of queries
    queries = config[:queries].split(',')
    responses = queries.map do |query|
      config[:query] = query
      client.count(build_request_options)['count']
    end
    result = evaluate_action(config[:action], responses)
    if config[:invert]
      if result < config[:crit]
        critical "Query compare (#{result}) was below critical threshold"
      elsif result < config[:warn]
        warning "Query compare (#{result}) was below warning threshold"
      else
        ok "Query compare (#{result}) was ok"
      end
    else
      if result > config[:crit] # rubocop:disable Style/IfInsideElse
        critical "Query compare (#{result}) was above critical threshold"
      elsif result > config[:warn]
        warning "Query compare (#{result}) was above warning threshold"
      else
        ok "Query compare (#{result}) was ok"
      end
    end
  rescue Elasticsearch::Transport::Transport::Errors::NotFound
    if config[:invert]
      if result < config[:crit]
        critical "Query compare (#{result}) was below critical threshold"
      elsif result < config[:warn]
        warning "Query compare (#{result}) was below warning threshold"
      else
        ok "Query compare (#{result}) was ok"
      end
    else
      ok 'No results found, compare was below thresholds'
    end
  end
end
