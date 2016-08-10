#! /usr/bin/env ruby
#
#   check-es-indices-sizes.rb
#
# DESCRIPTION:
#   This check sends a critical event when the indices mathing the date pattern
#     are above a MB value.
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
#   ./check-es-indices-sizes.rb -h localhost -p 9200 -m 155000
#
# NOTES:
#
# LICENSE:
#   Brendan Leon Gibat <brendan.gibat@gmail.com>
#   Released under the same terms as Sensu (the MIT license); see LICENSE
#   for details.
#

require 'sensu-plugin/check/cli'
require 'elasticsearch'
require 'aws_es_transport'
require 'sensu-plugins-elasticsearch'

class ESCheckIndicesSizes < Sensu::Plugin::Check::CLI
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

  option :used_percent,
         description: 'Percentage of bytes to use for indices matching pattern.',
         short: '-a USED_PERCENTAGE',
         long: '--used-percentage USED_PERCENTAGE',
         proc: proc(&:to_i),
         default: 80

  option :maximum_megabytes,
         description: 'Maximum number megabytes for date based indices to use.',
         short: '-m MAXIMUM_MEGABYTES',
         long: '--maximum-megabytes MAXIMUM_MEGABYTES',
         proc: proc(&:to_i),
         default: 0

  option :pattern_regex,
         description: 'Regular expression to use for matching date based indices. Four named groups are matched, pattern, year, month, day.',
         short: '-x PATTERN_REGEX',
         long: '--pattern-regex PATTERN_REGEX',
         default: '^(?<pattern>.*)-(?<year>\d\d\d\d)\.(?<month>\d\d?).(?<day>\d\d?)$'

  def get_indices_to_delete(starting_date, total_bytes_to_delete, indices_with_sizes)
    total_bytes_deleted = 0
    curr_date = DateTime.now

    indices_to_delete = []

    # We don't delete the current day, as it is most likely being used.
    while total_bytes_deleted < total_bytes_to_delete && starting_date < curr_date
      same_day_indices = indices_with_sizes.values.map do |pattern|
        pattern.select do |index|
          index['date'] == starting_date
        end
      end.flatten
      same_day_indices.each do |index|
        if total_bytes_deleted < total_bytes_to_delete
          indices_to_delete.push(index['index'])
          total_bytes_deleted += index['size']
        end
      end
      starting_date += 1
    end

    indices_to_delete
  end

  def build_indices_with_sizes
    indices_fs_stats = client.indices.stats store: true
    pattern_regex = Regexp.new(config[:pattern_regex])

    index_with_sizes = indices_fs_stats['indices'].keys.each_with_object({}) do |key, hash|
      matching_index = pattern_regex.match(key)
      unless matching_index.nil?
        base_pattern = matching_index[:pattern]
        unless base_pattern.nil?
          unless hash.include?(base_pattern)
            hash[base_pattern] = []
          end
          index_date = DateTime.new(matching_index[:year].to_i, matching_index[:month].to_i, matching_index[:day].to_i)
          hash[base_pattern].push(
            size: indices_fs_stats['indices'][key]['total']['store']['size_in_bytes'].to_i,
            date: index_date,
            index: key
          )
        end
      end
    end

    index_with_sizes
  end

  def run
    node_fs_stats = client.nodes.stats metric: 'fs,indices'
    nodes_being_used = node_fs_stats['nodes'].values.select { |node| node['indices']['store']['size_in_bytes'] > 0 }
    # rubocop:disable SingleLineBlockParams
    # rubocop:disable LineLength
    used_in_bytes = nodes_being_used.map { |node| node['fs']['data'].map { |data| data['total_in_bytes'] - data['available_in_bytes'] }.flatten }.flatten.inject { |sum, x| sum + x }
    # rubocop:enable LineLength
    total_in_bytes = nodes_being_used.map { |node| node['fs']['data'].map { |data| data['total_in_bytes'] }.flatten }.flatten.inject { |sum, x| sum + x }
    # rubocop:enable SingleLineBlockParams

    if config[:maximum_megabytes] > 0
      target_bytes_used = config[:maximum_megabytes] * 1_000_000
    else
      if config[:used_percent] > 100 || config[:used_percent] < 0
        critical 'You can not make used-percentages greater than 100 or less than 0.'
      end
      target_bytes_used = (total_in_bytes.to_f * (config[:used_percent].to_f / 100.0)).to_i
    end

    total_bytes_to_delete = used_in_bytes - target_bytes_used
    if total_bytes_to_delete <= 0
      ok "Used space in bytes: #{used_in_bytes}, Total in bytes: #{total_in_bytes}"
    end

    indices_with_sizes = build_indices_with_sizes

    oldest = indices_with_sizes.values.flatten.map { |index| index[:date] }.min
    indices_to_delete = get_indices_to_delete(oldest, total_bytes_to_delete, indices_with_sizes)

    critical "Not enough space, #{total_bytes_to_delete} bytes need to be deleted. Used space in bytes: " \
      "#{used_in_bytes}, Total in bytes: #{total_in_bytes}. Indices to delete: " \
      "#{indices_to_delete.sort.map { |i| "INDEX[#{i}]" }.join(', ')}"
  end
end
