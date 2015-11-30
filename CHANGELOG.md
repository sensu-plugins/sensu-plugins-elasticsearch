#Change Log
This project adheres to [Semantic Versioning](http://semver.org/).

This CHANGELOG follows the format listed at [Keep A Changelog](http://keepachangelog.com/)

## [Unreleased][unreleased]
### Changed
- Added AWS transport gem and configuration for check-es-query-* sensu calls to use --transport=AWS
- Update metrics-es-node-graphite.rb and check-es-node-status.rb for Elasticsearch 2.0
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

[unreleased]: https://github.com/sensu-plugins/sensu-plugins-elasticsearch/compare/0.1.2...HEAD
[0.1.2]: https://github.com/sensu-plugins/sensu-plugins-elasticsearch/compare/0.1.1...0.1.2
[0.1.1]: https://github.com/sensu-plugins/sensu-plugins-elasticsearch/compare/0.1.0...0.1.1
[0.1.0]: https://github.com/sensu-plugins/sensu-plugins-elasticsearch/compare/0.0.2...0.1.0
[0.0.2]: https://github.com/sensu-plugins/sensu-plugins-elasticsearch/compare/0.0.1...0.0.2
