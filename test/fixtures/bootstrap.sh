#!/bin/bash
set -e

apt-get update
apt-get install -y build-essential

source /etc/profile
DATA_DIR=/tmp/kitchen/data
RUBY_HOME=${MY_RUBY_HOME}


cd $DATA_DIR
SIGN_GEM=false gem build sensu-plugins-elasticsearch.gemspec
gem install sensu-plugins-elasticsearch-*.gem
