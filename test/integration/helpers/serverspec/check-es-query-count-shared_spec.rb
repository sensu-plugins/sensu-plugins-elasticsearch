# frozen_string_literal: true

require 'spec_helper'
require 'shared_spec'

gem_path = '/usr/local/bin'
check_name = 'check-es-query-count.rb'
check = "#{gem_path}/#{check_name}"
host = 'sensu-elasticsearch-6'

describe 'ruby environment' do
  it_behaves_like 'ruby checks', check
end

describe command("#{check} --host #{host} -q '*' --minutes-previous 1") do
  its(:exit_status) { should eq 0 }
  its(:stdout) { should match(/ESQueryCount OK: Query count \(\d+\) was ok/) }
end

describe command("#{check} --host #{host} -q '*' --headers='Content-Type: application/x-www-form-urlencoded' --minutes-previous 1") do
  its(:exit_status) { should eq 2 }
end