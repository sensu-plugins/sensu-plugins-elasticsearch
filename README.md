## Sensu-Plugins-elasticsearch

[![Build Status](https://travis-ci.org/sensu-plugins/sensu-plugins-elasticsearch.svg?branch=master)](https://travis-ci.org/sensu-plugins/sensu-plugins-elasticsearch)
[![Gem Version](https://badge.fury.io/rb/sensu-plugins-elasticsearch.svg)](http://badge.fury.io/rb/sensu-plugins-elasticsearch)
[![Code Climate](https://codeclimate.com/github/sensu-plugins/sensu-plugins-elasticsearch/badges/gpa.svg)](https://codeclimate.com/github/sensu-plugins/sensu-plugins-elasticsearch)
[![Test Coverage](https://codeclimate.com/github/sensu-plugins/sensu-plugins-elasticsearch/badges/coverage.svg)](https://codeclimate.com/github/sensu-plugins/sensu-plugins-elasticsearch)
[![Dependency Status](https://gemnasium.com/sensu-plugins/sensu-plugins-elasticsearch.svg)](https://gemnasium.com/sensu-plugins/sensu-plugins-elasticsearch)
[ ![Codeship Status for sensu-plugins/sensu-plugins-elasticsearch](https://codeship.com/projects/926f1e90-db39-0132-e370-5ad94843e341/status?branch=master)](https://codeship.com/projects/79569)

## Functionality

## Files
 * /bin/check-es-cluster-status
 * /bin/check-es-heap
 * /bin/metrics-es-node-graphite
 * /bin/check-es-file-descriptors
 * /bin/metrics-es-cluster
 * /bin/metrics-es-node

## Usage

## Installation

Add the public key (if you haven’t already) as a trusted certificate

```
gem cert --add <(curl -Ls https://raw.githubusercontent.com/sensu-plugins/sensu-plugins.github.io/master/certs/sensu-plugins.pem)
gem install sensu-plugins-elasticsearch -P MediumSecurity
```

You can also download the key from /certs/ within each repository.

#### Rubygems

`gem install sensu-plugins-elasticsearch`

#### Bundler

Add *sensu-plugins-elasticsearch* to your Gemfile and run `bundle install` or `bundle update`

#### Chef

Using the Sensu **sensu_gem** LWRP
```
sensu_gem 'sensu-plugins-elasticsearch' do
  options('--prerelease')
  version '0.0.1.alpha.1'
end
```

Using the Chef **gem_package** resource
```
gem_package 'sensu-plugins-elasticsearch' do
  options('--prerelease')
  version '0.0.1.alpha.1'
end
```

## Notes
