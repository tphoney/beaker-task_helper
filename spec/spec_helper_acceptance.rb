require 'beaker'
require 'beaker-rspec'
require 'beaker/task_helper'

RSpec.configure do |c|
  c.before :suite do
    hosts.each do |host|
      install_package(host, 'facter')
    end
  end
end
