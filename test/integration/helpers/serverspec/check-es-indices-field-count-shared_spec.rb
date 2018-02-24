# frozen_string_literal: true

require 'spec_helper'
require 'shared_spec'

gem_path = '/usr/local/bin'
check_name = 'check-es-indices-field-count.rb'
check = "#{gem_path}/#{check_name}"
host = 'sensu-elasticsearch-6'

describe 'ruby environment' do
  it_behaves_like 'ruby checks', check
end

describe command("#{check} --host #{host} -i field_count_index -l 10 -w 85 -c 95") do
  its(:exit_status) { should eq 0 }
  its(:stdout) { should match(/ESIndicesFieldCount OK/) }
end

describe command("#{check} --host #{host} -l 10 -w 85 -c 95") do
  its(:exit_status) { should eq 0 }
  its(:stdout) { should match(/ESIndicesFieldCount OK/) }
end

describe command("#{check} --host #{host} -i field_count_index -l 10 -w 70 -c 90") do
  its(:exit_status) { should eq 1 }
end

describe command("#{check} --host #{host} -i field_count_index -l 10 -w 70 -c 80") do
  its(:exit_status) { should eq 2 }
end
