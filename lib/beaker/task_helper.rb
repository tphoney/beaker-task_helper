require 'beaker'

# Beaker task Helper
module Beaker::TaskHelper # rubocop:disable Style/ClassAndModuleChildren
  include Beaker::DSL
  include Beaker::DSL::Helpers::FacterHelpers

  def install_bolt_on(hosts)
    on(hosts, "/opt/puppetlabs/puppet/bin/gem install --source http://rubygems.delivery.puppetlabs.net bolt -v '> 0.0.1'", acceptable_exit_codes: [0, 1]).stdout
  end

  def pe_install?
    ENV['PUPPET_INSTALL_TYPE'] =~ %r{pe}i
  end

  def run_puppet_access_login(user:, password: '~!@#$%^*-/ aZ', lifetime: '5y')
    on(master, puppet('access', 'login', '--username', user, '--lifetime', lifetime), stdin: password)
  end
  
  def run_task(task_name:, params: nil, password: DEFAULT_PASSWORD)
    if pe_install?
      run_puppet_task(task_name: task_name, params: params)
    else
      run_bolt_task(task_name: task_name, params: params, password: password)
    end
  end

  def run_bolt_task(task_name:, params: nil, password: DEFAULT_PASSWORD)
    on(default, "/opt/puppetlabs/puppet/bin/bolt task run #{task_name} --modules /etc/puppetlabs/code/modules --nodes #{fact_on(default, 'fqdn')} --password #{password} #{params}", acceptable_exit_codes: [0, 1]).stdout # rubocop:disable Metrics/LineLength
  end
  
  def run_puppet_task(task_name:, params: nil)
    on(master, puppet('task', 'run', task_name, '--nodes', fact_on(master, 'fqdn'), params.to_s), acceptable_exit_codes: [0, 1]).stdout
  end
  
  def expect_multiple_regexes(result:, regexes:)
    regexes.each do |regex|
      expect(result).to match(regex)
    end
  end
end
