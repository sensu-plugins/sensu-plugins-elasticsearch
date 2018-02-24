#! /usr/bin/env ruby
#
#   check-es-indices-field-count
#
# DESCRIPTION:
#   This plugin checks if the number of fields in ES index(es) is approaching limit. ES by default
#   puts this limit at 1000 fields per index.
#
# OUTPUT:
#   plain text
#
# PLATFORMS:
#   Linux
#
# DEPENDENCIES:
#   gem: sensu-plugin
#
# USAGE:
#   This example checks if the number of fields for an index is reaching its limit set in
#   index.mapping.total_fields.limit. This check takes as paramater the index name or
#   comma-separated list of indices, and optionally the type to check on. If type is not specified,
#   all types in index are examined.
#   You can also specify an optional value for the limit. When omitted, this will default to 1000.
#
#   check-es-indices-field-count.rb -h <hostname or ip> -p 9200
#           -i <index1>,<index2> --types <type_in_index> -w <pct> -c <pct>
#
#   If any indices crossing the specified thresholds (warning/critical), beside the appropriate return code
#   this check will also output a list of indices with the violated percentage for further troubleshooting.
# NOTES:
#
# LICENSE:
#   CloudCruiser <devops@hpe.com>
#   Released under the same terms as Sensu (the MIT license); see LICENSE
#   for details.
#

require 'sensu-plugin/check/cli'
require 'elasticsearch'
require 'sensu-plugins-elasticsearch'
require 'json'

#
# ES Indices Field Count
#
class ESIndicesFieldCount < Sensu::Plugin::Check::CLI
  include ElasticsearchCommon

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

  option :index,
         description: 'Elasticsearch indices to check against.
         Comma-separated list of index names to search.
         Default to `_all` if omitted. Accepts wildcards',
         short: '-i INDEX',
         long: '--indices INDEX',
         default: '_all'

  option :types,
         description: 'Elasticsearch types of index to check against.
         Comma-separated list of types. When omitted, all types are checked against.',
         short: '-T TYPES',
         long: '--types TYPES'

  option :limit,
         description: 'Default number of fields limit to compare against.
         Elasticsearch defaults this to 1000 if none is specied in index setting.',
         short: '-l',
         long: '--limit LIMIT',
         proc: proc(&:to_i),
         default: 1000

  option :warn,
         short: '-w PCT',
         long: '--warn PCT',
         description: 'WARNING threshold in percentage',
         proc: proc(&:to_f),
         default: 85.0

  option :crit,
         short: '-c N',
         long: '--crit N',
         description: 'CRITICAL threshold in percentage',
         proc: proc(&:to_f),
         default: 95.0

  def indexfieldcount
    index_field_count = {}
    mappings = client.indices.get_mapping index: config[:index], type: config[:types]
    mappings.each do |index, index_mapping|
      unless index_mapping['mappings'].nil?
        type_field_count = {}
        index_mapping['mappings'].each do |type, type_mapping|
          fieldcount = if type_mapping['properties'].nil?
                         0
                       else
                         type_mapping['properties'].length
                       end
          type_field_count[type] = fieldcount
        end

        index_field_count[index] = type_field_count
      end
    end

    index_field_count
  end

  def fieldlimitsetting
    field_limit_setting = {}
    settings = client.indices.get_settings index: config[:index]
    settings.each do |index, index_setting|
      index_field_limit = index_setting['settings']['index.mapping.total_fields.limit']
      # when no index.mapping.total_fields.limit, use value of the limit parameter, which defaults to 1000.
      index_field_limit = config[:limit] if index_field_limit.nil?
      field_limit_setting[index] = { 'limit' => index_field_limit }
    end

    field_limit_setting
  end

  def run
    fieldcounts = indexfieldcount
    limits = fieldlimitsetting

    warnings = {}
    criticals = {}

    if fieldcounts.empty?
      unknown "Can't find any indices."
    end

    fieldcounts.each do |index, counts|
      counts.each do |type, count|
        pct = count.to_f / limits[index]['limit'] * 100

        if config[:warn] <= pct && pct < config[:crit]
          warnings[index] = {} if warnings[index].nil?
          warnings[index][type] = pct.round(2)
        end

        if config[:crit] <= pct
          criticals[index] = {} if criticals[index].nil?
          criticals[index][type] = pct.round(2)
        end
      end
    end

    unless criticals.empty?
      critical "Number of fields in indices is at critical level.
#{JSON.pretty_generate(criticals)}"
    end

    unless warnings.empty?
      warning "Number of fields in indices is at warning level.
#{JSON.pretty_generate(warnings)}"
    end

    ok
  end
end
