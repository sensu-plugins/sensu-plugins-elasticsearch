#Change Log
This project adheres to [Semantic Versioning](http://semver.org/).

This CHANGELOG follows the format listed at [Keep A Changelog](http://keepachangelog.com/)

## [Unreleased]

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

[Unreleased]: https://github.com/sensu-plugins/sensu-plugins-elasticsearch/compare/0.4.3...HEAD
[0.4.2]: https://github.com/sensu-plugins/sensu-plugins-elasticsearch/compare/0.4.2...0.4.3
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
