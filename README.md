[![Sensu Bonsai Asset](https://img.shields.io/badge/Bonsai-Download%20Me-brightgreen.svg?colorB=89C967&logo=sensu)](https://bonsai.sensu.io/assets/sensu-plugins/sensu-plugins-elasticsearch)
[![Build Status](https://travis-ci.org/sensu-plugins/sensu-plugins-elasticsearch.svg?branch=master)](https://travis-ci.org/sensu-plugins/sensu-plugins-elasticsearch)
[![Gem Version](https://badge.fury.io/rb/sensu-plugins-elasticsearch.svg)](http://badge.fury.io/rb/sensu-plugins-elasticsearch)
[![Code Climate](https://codeclimate.com/github/sensu-plugins/sensu-plugins-elasticsearch/badges/gpa.svg)](https://codeclimate.com/github/sensu-plugins/sensu-plugins-elasticsearch)
[![Test Coverage](https://codeclimate.com/github/sensu-plugins/sensu-plugins-elasticsearch/badges/coverage.svg)](https://codeclimate.com/github/sensu-plugins/sensu-plugins-elasticsearch)
[![Dependency Status](https://gemnasium.com/sensu-plugins/sensu-plugins-elasticsearch.svg)](https://gemnasium.com/sensu-plugins/sensu-plugins-elasticsearch)

## Sensu Plugins ElasticSearch Plugin

- [Overview](#overview)
- [Files](#files)
- [Usage examples](#usage-examples)
- [Configuration](#configuration)
  - [Sensu Go](#sensu-go)
    - [Asset registration](#asset-registration)
    - [Asset definition](#asset-definition)
    - [Check definition](#check-definition)
    - [Handler definition](#handler-definition)
  - [Sensu Core](#sensu-core)
    - [Check definition](#check-definition)
- [Installation from source](#installation-from-source)
- [Additional notes](#additional-notes)
- [Contributing](#contributing)

### Overview

This plugin provides native ElasticSearch instrumentation for monitoring and metrics collection, including service health and metrics for cluster, node, and more.

### Files
 * /bin/check-es-circuit-breakers.rb
 * /bin/check-es-cluster-health.rb
 * /bin/check-es-cluster-status.rb
 * /bin/check-es-file-descriptors.rb
 * /bin/check-es-heap.rb
 * /bin/check-es-indices-field-count.rb
 * /bin/check-es-indexes.rb
 * /bin/check-es-indicies-sizes.rb
 * /bin/check-es-node-status.rb
 * /bin/check-es-node-average.rb
 * /bin/check-es-query-count.rb
 * /bin/check-es-query-exists.rb
 * /bin/check-es-query-ratio.rb
 * /bin/check-es-shard-allocation-status.rb
 * /bin/handler-es-delete-indices.rb
 * /bin/metrics-es-cluster.rb
 * /bin/metrics-es-node.rb
 * /bin/metrics-es-node-graphite.rb

**check-es-circuit-breakers**
Checks whether the ElasticSearch circuit breakers have been tripped using the node stats API.

**check-es-cluster-health**
Checks the ElasticSearch cluster health and status.

**check-es-cluster-status**
Checks the ElasticSearch cluster status using its API.

**check-es-file-descriptors**
Checks the ElasticSearch file descriptor usage using its API.

**check-es-heap**
Checks ElasticSearch's Java heap usage using its API.

**check-es-indices-field-count**
Checks if the number of fields in ElasticSearch indexes is approaching the limit. By default, ElasticSearch sets this limit at 1000 fields per index.

**check-es-indexes**
Checks a node for duplicate indexes.

**check-es-indicies-sizes**
Sends a critical event when the indices that match the date pattern are over a MB value.

**check-es-node-status**
Checks the ElasticSearch node status using its API.

**check-es-query-average** and **check-es-query-count**
Check an ElasticSearch query.

**check-es-query-exists**
Checks whether ElasticSearch query results exist.

**check-es-query-ratio**
Checks the ratio between the results of two Elasticsearch queries.

**check-es-shard-allocation-status**
Checks ElasticSearch shard allocation setting status.

**handler-es-delete-indices**
Deletes indices.

**metrics-es-cluster** and **metrics-es-node**
Uses the ElasticSearch API to collect metrics. Produces a JSON document outputted to STDOUT. An exit status of 0 indicates that the plugin successfully collected and produced metrics.

**metrics-es-node-graphite**
Creates node metrics from the ElasticSearch API.

## Usage examples

### Help

**check-es-cluster-health.rb**
```
Usage: check-es-cluster-health.rb (options)
        --alert-status STATUS        Only alert when status matches given RED/YELLOW/GREEN or if blank all statuses (included in ['RED', 'YELLOW', 'GREEN', ''])
    -h, --host HOST                  Elasticsearch host
    -l, --level LEVEL                Level of detail to check returend information ("cluster", "indices", "shards").
        --local                      Return local information, do not retrieve the state from master node.
    -P, --password PASSWORD          Elasticsearch connection password
    -p, --port PORT                  Elasticsearch port
        --region REGION              Region (necessary for AWS Transport)
    -s, --scheme SCHEME              Elasticsearch connection scheme, defaults to https for authenticated connections
    -t, --timeout TIMEOUT            Elasticsearch query timeout in seconds
        --transport TRANSPORT        Transport to use to communicate with ES. Use "AWS" for signed AWS transports.
    -u, --user USER                  Elasticsearch connection user
```

**handler-es-delete-indices.rb**
```
Usage: handler-es-delete-indices.rb (options)
    -e, --event-regex EVENT_REGEX    Elasticsearch connection user
    -h, --host HOST                  Elasticsearch host
        --map-go-event-into-ruby     Enable Sensu Go to Sensu Ruby event mapping. Alternatively set envvar SENSU_MAP_GO_EVENT_INTO_RUBY=1.
    -P, --password PASSWORD          Elasticsearch connection password
    -p, --port PORT                  Elasticsearch port
        --region REGION              Region (necessary for AWS Transport)
    -s, --scheme SCHEME              Elasticsearch connection scheme, defaults to https for authenticated connections
    -t, --timeout TIMEOUT            Elasticsearch query timeout in seconds
        --transport TRANSPORT        Transport to use to communicate with ES. Use "AWS" for signed AWS transports.
    -u, --user USER                  Elasticsearch connection user
```

**metrics-es-cluster.rb**
```
Usage: metrics-es-cluster.rb (options)
    -a, --allow-non-master           Allow check to run on non-master nodes
        --cert-file CERT_FILE        Cert file to use
    -o, --enable-percolate           Enables percolator stats (ES 2 and older only)
    -h, --host HOST                  Elasticsearch host
    -e, --https                      Enables HTTPS
    -P, --password PASS              Elasticsearch Password
    -p, --port PORT                  Elasticsearch port
    -s, --scheme SCHEME              Metric naming scheme, text to prepend to metric
    -t, --timeout SECS               Sets the connection timeout for REST client
    -u, --user USER                  Elasticsearch User
```

## Configuration
### Sensu Go
#### Asset registration

Assets are the best way to make use of this plugin. If you're not using an asset, please consider doing so! If you're using sensuctl 5.13 or later, you can use the following command to add the asset: 

`sensuctl asset add sensu-plugins/sensu-plugins-elasticsearch`

If you're using an earlier version of sensuctl, you can download the asset definition from [this project's Bonsai asset index page](https://bonsai.sensu.io/assets/sensu-plugins/sensu-plugins-elasticsearch).

#### Asset definition

```yaml
---
type: Asset
api_version: core/v2
metadata:
  name: sensu-plugins-elasticsearch
spec:
  url: https://assets.bonsai.sensu.io/74b03bd9c8f4cf015278eef0c3d638988644aa73/sensu-plugins-elasticsearch_4.0.1_centos_linux_amd64.tar.gz
  sha512: b6c3ed1583b59763eb2ebd06e5f6c87965406faf46fe2b050dcf91ddc8ca60fa365f02b8959b93250336d2d57cb432929dd0f408fa34ba44bd3d25c84f8311fb
```

#### Check definition

```yaml
---
type: CheckConfig
spec:
  command: "check-es-cluster-health.rb"
  handlers: []
  high_flap_threshold: 0
  interval: 10
  low_flap_threshold: 0
  publish: true
  runtime_assets:
  - sensu-plugins/sensu-plugins-elasticsearch
  - sensu/sensu-ruby-runtime
  subscriptions:
  - linux
```

#### Handler definition

```yaml
---
type: Handler
api_version: core/v2
metadata:
  name: delete-indices
  namespace: default
spec:
  handlers:
  - handler-es-delete-indices
  type: pipe
```

### Sensu Core

#### Check definition
```json
{
  "checks": {
    "check-cluster-health": {
      "command": "check-es-cluster-health.rb",
      "subscribers": ["linux"],
      "interval": 10,
      "refresh": 10,
      "handlers": ["influxdb"]
    }
  }
}
```

## Installation from source

### Sensu Go

See the instructions above for [asset registration](#asset-registration).

### Sensu Core

Install and setup plugins on [Sensu Core](https://docs.sensu.io/sensu-core/latest/installation/installing-plugins/).

## Additional notes

### Sensu Go Ruby Runtime Assets

The Sensu assets packaged from this repository are built against the Sensu Ruby runtime environment. When using these assets as part of a Sensu Go resource (check, mutator, or handler), make sure to include the corresponding [Sensu Ruby Runtime Asset](https://bonsai.sensu.io/assets/sensu/sensu-ruby-runtime) in the list of assets needed by the resource.

### Use this plugin with Sensu Go

To use `handler-es-delete-indices.rb` with Sensu Go, you will need to use the event mapping command line option. See `handler-es-delete-indices.rb --help` for details. Read the [sensu-plugin README](https://github.com/sensu-plugins/sensu-plugin#sensu-go-enablement) for more information about the event mapping functionality.

## Testing

This repository uses the [Kitchen](https://kitchen.ci/) suite for its tests.

The test suite uses an elasticsearch instance to have passing tests. Execute the following command to create a mock elasticsearch 6 instance:
```bash
docker run -d --name sensu-elasticsearch-6 docker.elastic.co/elasticsearch/elasticsearch:6.2.2
```

Run the tests:
```bash
bundle install --path vendor/bundle
bundle exec kitchen test
```

Sample output for all tests running successfully is available in [this gist](https://gist.github.com/alexandrustaetu/d19feea1296d2ce7e367542265252d7a).

## Contributing

See [CONTRIBUTING.md](https://github.com/sensu-plugins/sensu-plugins-elasticsearch/blob/master/CONTRIBUTING.md) for information about contributing to this plugin.

