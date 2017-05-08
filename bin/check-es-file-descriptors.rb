#! /usr/bin/env ruby
#
#   check-es-file-descriptors
#
# DESCRIPTION:
#   This plugin checks the ElasticSearch file descriptor usage, using its API.
#
# OUTPUT:
#   plain text
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
#   Author: S. Zachariah Sprackett <zac@sprackett.com>
#   Released under the same terms as Sensu (the MIT license); see LICENSE
#   for details.
#

require 'sensu-plugin/check/cli'
require 'rest-client'
require 'json'
require 'base64'

#
# ES File Descriptiors
#
class ESFileDescriptors < Sensu::Plugin::Check::CLI
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

  option :critical,
         description: 'Critical percentage of FD usage',
         short: '-c PERCENTAGE',
         proc: proc(&:to_i),
         default: 90

  option :warning,
         description: 'Warning percentage of FD usage',
         short: '-w PERCENTAGE',
         proc: proc(&:to_i),
         default: 80

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

  def get_es_resource(resource)
    headers = {}
    if config[:user] && config[:password]
      auth = 'Basic ' + Base64.strict_encode64("#{config[:user]}:#{config[:password]}").chomp
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
  rescue RestClient::ServiceUnavailable
    warning 'Service is unavailable'
  end

  def acquire_es_version
    info = get_es_resource('/')
    info['version']['number']
  end

  def es_version
    @es_version ||= Gem::Version.new(acquire_es_version)
  end

  def acquire_open_fds
    stats = if es_version < Gem::Version.new('5.0.0')
              get_es_resource('/_nodes/_local/stats?process=true')
            else
              get_es_resource('/_nodes/_local/stats/process')
            end
    begin
      keys = stats['nodes'].keys
      stats['nodes'][keys[0]]['process']['open_file_descriptors'].to_i
    rescue NoMethodError
      warning 'Failed to retrieve open_file_descriptors'
    end
  end

  def acquire_max_fds
    info = if es_version < Gem::Version.new('2.0.0')
             get_es_resource('/_nodes/_local?process=true')
           elsif es_version < Gem::Version.new('5.0.0')
             get_es_resource('/_nodes/_local/stats?process=true')
           else
             get_es_resource('/_nodes/_local/stats/process')
           end
    begin
      keys = info['nodes'].keys
      info['nodes'][keys[0]]['process']['max_file_descriptors'].to_i
    rescue NoMethodError
      warning 'Failed to retrieve max_file_descriptors'
    end
  end

  def run
    open = acquire_open_fds
    max = acquire_max_fds
    used_percent = ((open.to_f / max.to_f) * 100).to_i

    if used_percent >= config[:critical]
      critical "fd usage #{used_percent}% exceeds #{config[:critical]}% (#{open}/#{max})"
    elsif used_percent >= config[:warning]
      warning "fd usage #{used_percent}% exceeds #{config[:warning]}% (#{open}/#{max})"
    else
      ok "fd usage at #{used_percent}% (#{open}/#{max})"
    end
  end
end
