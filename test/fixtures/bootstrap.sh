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

# hostnamectl
if [ $(curl -sI -XGET sensu-elasticsearch-6:9200/field_count_index | grep -c '200 OK') -ne 0 ]; then
  # clean up existing index
  echo "Clean up existing index field_count_index"
  curl -XDELETE sensu-elasticsearch-6:9200/field_count_index
  echo
fi

echo
echo "Create index field_count_index"
echo
curl -XPUT sensu-elasticsearch-6:9200/field_count_index

echo
echo "Create mapping for index field_count_index"
echo
curl --header 'Content-Type: application/json' -XPUT sensu-elasticsearch-6:9200/field_count_index/_mapping/test -d @- <<'EOF'
{
"properties": {
  "field1": {
    "type": "boolean"
  },
  "field2": {
    "type": "boolean"
  },
  "field3": {
    "type": "boolean"
  },
  "field4": {
    "type": "boolean"
  },
  "field5": {
    "type": "boolean"
  },
  "field6": {
    "type": "boolean"
  },
  "field7": {
    "type": "boolean"
  },
  "field8": {
    "type": "boolean"
  }
}
}
EOF
