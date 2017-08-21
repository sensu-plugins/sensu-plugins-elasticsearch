# Change Log
This project adheres to [Semantic Versioning](http://semver.org/).

This CHANGELOG follows the format listed at [Keep A Changelog](http://keepachangelog.com/)

## [Unreleased]

### Fixed
- bin/check-es-query-ratio.rb: added support to define float thresholds (@cgarciaarano)

## [1.6.0] - 2017-08-18
### Added
- bin/check-es-query-ratio.rb: added option to avoid triggering alert if divisor is 0 (@cgarciaarano)

## [1.5.3] - 2017-08-17
### Fixed
- bin/check-es-query-ratio.rb: ratio is performed by a float division, instead of integer division (@cgarciaarano)

## [1.5.2] - 2017-08-12
### Fixed
- check-es-query-ratio.rb: Fix when divisor = 0 (@cgarciaarano)
## [1.5.1] - 2017-08-03
### Fixed
- bin/metrics-es-cluster.rb: missing data no longer causes invalid metrics by defaulting to 0 (@TheKevJames)

## [1.5.0] - 2017-07-26
### Added
- check-es-query-average.rb: check of average result by field (@ilavender)

## [1.4.1] - 2017-07-13
### Fixed
- use timestamp_field from config for sorting in Kibana (@osgida)

## [1.4.0] - 2017-07-04
### Added
- added ruby 2.4 testing (@majormoses)
- check-es-shard-allocation-status.rb: HTTP Basic Auth support added  (@cihangirbesiktas)
- check-es-shard-allocation-status.rb: timeout option for rest calls (@cihangirbesiktas)


### Fixed
- PR template spell "compatibility" correctly. (@majormoses)

## [1.3.1] - 2017-05-22
### Fixed
- Conversion of previous_months option to Seconds (@guptaishabh)

## [1.3.0] - 2017-05-08
### Fixed
- Use strict Base64 encoding to fix base64 encoding/netty issue (@msblum)

## [1.2.0] - 2017-05-03
### Fixed
- metrics-es-cluster.rb: Check to see if cluster key exists in transient_settings before trying to use it. (@RAR)
### Added
- Add option to run check-es-shard-allocation-status.rb on non master nodes (@Evesy)
- Fixed check-es-shard-allocation-status.rb for Elasticsearch 5.x compatibility (@Evesy)

## [1.1.3] - 2017-01-04
### Fixed
- metrics-es-cluster/metrics-es-node-graphite.rb: Fix Elasticsearch 5.0 compatability (@terjesannum)

## [1.1.2] - 2016-12-29
### Fixed
- Fixed metrics-es-node-graphite.rb was not compatible with Elasticsearch 5.0 (@woqer)
- Make query lib compatible with ES 5+ (@jackfengji)

## [1.1.1] - 2016-11-26
### Fixed
- Fixed check-es-file-descriptors.rb was not compatible with Elasticsearch 5.0 (@woqer)

## [1.1.0] - 2016-11-14
### Changed
- Changed check-es-heap.rb to be compatible with Elasticsearch 5.0 (@christianherro)

### Added
- Added check-es-query-ratio.tb to support ratio-type checks (@alcasim)
- Added direct support to check-es-indices-size.rb to delete indicies without the handler-es-delete-indices.rb

### Fixed
- aws-sdk 2.5.x breaks aws-es-transport (@sstarcher)
- check-es-indicies-size - fix array mapping by (@nyxcharon)

## [1.0.0] - 2016-07-29
### Added
- Added AWS transport gem and configuration for check-es-query-* sensu calls to use --transport=AWS (@brendangibat)
- Added a rescue for 503 on several checks: (@majormoses)
 - check-es-circuit-breakers.rb
 - check-es-cluster-status.rb
 - check-es-file-descriptors.rb
 - check-es-heap.rb
- Added option --localhost for check-es-circuit-breakers.rb to only check its local node for broken circuit (@majormoses)
- Add Ruby 2.3.0 support (@eheydrick)
- Allow using newer patch versions of elasticsearch gem within the same minor (@majormoses)
- Add check-es-cluster-health to check Elasticsearch cluster health and status (@brendangibat)
- Add check-es-indices-size to check if indicies grow above a certain size (@brendangibat)
- Add handler-es-delete-indices handler to delete indicies (@brendangibat)

### Removed
- Ruby 1.9.3 support (@eheydrick)

### Changed
- Update to Rubocop 0.40 and cleanup (@eheydrick)

### Fixed
- check-es-indicies-size.rb - broken for newer updates

## [0.5.3] - 2016-04-02
### Added
- check-es-indexes (check for dup indexes) (Yieldbot)
- check-es-shard-allocation (check ElasticSearch shard allocation persistent and transient settings) (Yieldbot)
- Adding offset flag to allow specifying of a end time offset
- Adding custom timestamp field feature to check-es-query-count and check-es-query-exists
- Added support for https requests (OrbotixInc)


## [0.4.3] - 2016-02-22
### Fixed
- metrics-es-heap.rb: Assignment of node from the stats variable happened before stats was assigned.  Moved node assignment to be after stats assignment.

## [0.4.2] - 2016-01-27
### Added
- metrics-es-cluster.rb: Added i/o cluster stats

## [0.4.1] - 2016-01-26
### Fixed
- metrics-es-cluster.rb: Allow metrics to be gathered even if the cluster has zero documents. Also updated cache name for Elasticsearch 2.0+
- metrics-es-node-graphite.rb: Update node stats for Elasticsearch 2.0+

## [0.4.0] - 2016-01-22
### Added
- metrics-es-node-graphite.rb: Added file system and cpu stats
- metrics-es-cluster.rb: Added cluster metrics including optional percolator metrics, allocation status, and option to run on non-master nodes

## [0.3.2] - 2015-12-29
### Changed
- Update metrics-es-node.rb for Elasticsearch 2.0

## [0.3.1] - 2015-12-29
### Changed
- Update metrics-es-node.rb to use version checks consistent with other metrics
- Update metrics-es-cluster.rb to use `_stats` api instead of `/_count?q=*:*` see [Unbound wildcard range query cripples es on larger installs #20](https://github.com/sensu-plugins/sensu-plugins-elasticsearch/issues/20)

## [0.3.0] - 2015-11-18
### Changed
- Update metrics-es-node-graphite.rb, check-es-node-status.rb, and check-es-file-descriptors.rb for Elasticsearch 2.0
- Update elasticsearch gem to 1.0.14

### Added
- Add check-es-cluster-health that checks health status with elasticsearch gem and can use AWS transport for checks.
- Add check-es-circuit-breakers.rb, to alert when circuit breakers have been tripped

## [0.2.0] - 2015-10-15
### Changed
- cluster-status check: added a new `status_timeout` option that will use elasticsearch's [`wait_for_status` parameter](https://www.elastic.co/guide/en/elasticsearch/reference/current/cluster-health.html#request-params) and wait up to the given number of seconds for the cluster to be green. This pervents false alerting during normal elasticsearch operations.

## [0.1.2] - 2015-08-11
### Added
- add parameters for elasticsearch auth

## [0.1.1] - 2015-07-14
### Changed
- updated sensu-plugin gem to 1.2.0

## [0.1.0] - 2015-07-06
### Added
- `check-es-node-status` node status check

### Fixed
- uri resource path for `get_es_resource` method

### Changed
- `get_es_resource` URI path needs to start with `/`
- clean cruft from Rakefile
- put deps in alpha order in gemspec
- update documentation links in README and CONTRIBUTING

## [0.0.2] - 2015-06-02
### Fixed
- added binstubs

### Changed
- removed cruft from /lib

## 0.0.1 - 2015-05-21
### Added
- initial release


[Unreleased]: https://github.com/sensu-plugins/sensu-plugins-elasticsearch/compare/1.6.0...HEAD
[1.6.0]: https://github.com/sensu-plugins/sensu-plugins-elasticsearch/compare/1.5.3...1.6.0
[1.5.3]: https://github.com/sensu-plugins/sensu-plugins-elasticsearch/compare/1.5.2...1.5.3
[1.5.2]: https://github.com/sensu-plugins/sensu-plugins-elasticsearch/compare/1.5.1...1.5.2
[1.5.1]: https://github.com/sensu-plugins/sensu-plugins-elasticsearch/compare/1.5.0...1.5.1
[1.5.0]: https://github.com/sensu-plugins/sensu-plugins-elasticsearch/compare/1.4.1...1.5.0
[1.4.1]: https://github.com/sensu-plugins/sensu-plugins-elasticsearch/compare/1.4.0...1.4.1
[1.4.0]: https://github.com/sensu-plugins/sensu-plugins-elasticsearch/compare/1.3.1...1.4.0
[1.3.1]: https://github.com/sensu-plugins/sensu-plugins-elasticsearch/compare/1.3.0...1.3.1
[1.3.0]: https://github.com/sensu-plugins/sensu-plugins-elasticsearch/compare/1.2.0...1.3.0
[1.2.0]: https://github.com/sensu-plugins/sensu-plugins-elasticsearch/compare/1.1.3...1.2.0
[1.1.3]: https://github.com/sensu-plugins/sensu-plugins-elasticsearch/compare/1.1.2...1.1.3
[1.1.2]: https://github.com/sensu-plugins/sensu-plugins-elasticsearch/compare/1.1.1...1.1.2
[1.1.1]: https://github.com/sensu-plugins/sensu-plugins-elasticsearch/compare/1.1.0...1.1.1
[1.1.0]: https://github.com/sensu-plugins/sensu-plugins-elasticsearch/compare/1.0.0...1.1.0
[1.0.0]: https://github.com/sensu-plugins/sensu-plugins-elasticsearch/compare/0.5.3...1.0.0
[0.5.3]: https://github.com/sensu-plugins/sensu-plugins-elasticsearch/compare/0.4.3...0.5.3
[0.4.3]: https://github.com/sensu-plugins/sensu-plugins-elasticsearch/compare/0.4.2...0.4.3
[0.4.2]: https://github.com/sensu-plugins/sensu-plugins-elasticsearch/compare/0.4.1...0.4.2
[0.4.1]: https://github.com/sensu-plugins/sensu-plugins-elasticsearch/compare/0.4.0...0.4.1
[0.4.0]: https://github.com/sensu-plugins/sensu-plugins-elasticsearch/compare/0.3.2...0.4.0
[0.3.2]: https://github.com/sensu-plugins/sensu-plugins-elasticsearch/compare/0.3.1...0.3.2
[0.3.1]: https://github.com/sensu-plugins/sensu-plugins-elasticsearch/compare/0.3.0...0.3.1
[0.3.0]: https://github.com/sensu-plugins/sensu-plugins-elasticsearch/compare/0.2.0...0.3.0
[0.2.0]: https://github.com/sensu-plugins/sensu-plugins-elasticsearch/compare/0.1.2...0.2.0
[0.1.2]: https://github.com/sensu-plugins/sensu-plugins-elasticsearch/compare/0.1.1...0.1.2
[0.1.1]: https://github.com/sensu-plugins/sensu-plugins-elasticsearch/compare/0.1.0...0.1.1
[0.1.0]: https://github.com/sensu-plugins/sensu-plugins-elasticsearch/compare/0.0.2...0.1.0
[0.0.2]: https://github.com/sensu-plugins/sensu-plugins-elasticsearch/compare/0.0.1...0.0.2
