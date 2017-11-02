require 'beaker'

# Beaker task Helper
module Beaker::TaskHelper # rubocop:disable Style/ClassAndModuleChildren
  include Beaker::DSL

  def puppet_version
    (on default, puppet('--version')).output.chomp
  end

  DEFAULT_PASSWORD = if default[:hypervisor] == 'vagrant'
                      'puppet'
                     elsif default[:hypervisor] == 'vcloud'
                       'Qu@lity!'
                     else
                       'root'
                     end

  BOLT_VERSION = '>= 0.7.0'

  def install_bolt_on(hosts, version = BOLT_VERSION)
    unless default[:docker_image_commands].nil?
      if default[:docker_image_commands].to_s.include? "yum"
        on(hosts, "yum install -y make gcc ruby-devel", acceptable_exit_codes: [0, 1]).stdout
      elsif default[:docker_image_commands].to_s.include? "apt-get"
        on(hosts, "apt-get install -y make gcc ruby-dev", acceptable_exit_codes: [0, 1]).stdout
      end

    end
    on(hosts, "/opt/puppetlabs/puppet/bin/gem install --source http://rubygems.delivery.puppetlabs.net bolt -v '#{BOLT_VERSION}'", acceptable_exit_codes: [0, 1]).stdout
  end

  def pe_install?
    ENV['PUPPET_INSTALL_TYPE'] =~ %r{pe}i
  end

  def run_puppet_access_login(user:, password: '~!@#$%^*-/ aZ', lifetime: '5y')
    on(master, puppet('access', 'login', '--username', user, '--lifetime', lifetime), stdin: password)
  end

  def run_task(task_name:, params: nil, password: DEFAULT_PASSWORD, format: 'human')
    if pe_install?
      output = run_puppet_task(task_name: task_name, params: params)
    else
      output = run_bolt_task(task_name: task_name, params: params, password: password)
    end

    if format == 'json'
      output = JSON.parse(output)
      output['items'][0]
    else
      output
    end
  end

  def run_bolt_task(task_name:, params: nil, password: DEFAULT_PASSWORD, host: "localhost", format: 'human')
    if params.class == Hash
      on(default, "/opt/puppetlabs/puppet/bin/bolt task run #{task_name} --insecure -m /etc/puppetlabs/code/modules --nodes #{host} --password #{password} --params '#{params.to_json}'", acceptable_exit_codes: [0, 1]).stdout # rubocop:disable Metrics/LineLength
    else
      on(default, "/opt/puppetlabs/puppet/bin/bolt task run #{task_name} --insecure -m /etc/puppetlabs/code/modules --nodes #{host} --password #{password} #{params}", acceptable_exit_codes: [0, 1]).stdout # rubocop:disable Metrics/LineLength
    end
  end

  def run_puppet_task(task_name:, params: nil, host: 'localhost', format: 'human')
    args = ['task', 'run', task_name, '--nodes', host, ]
    if params.class == Hash
      args << '--params'
      args << params.to_json
    else
      args << params
    end
    if format == 'json'
      args << '--format'
      args << 'json'
    end
    on(master, puppet(*args), acceptable_exit_codes: [0, 1]).stdout
  end

  def expect_multiple_regexes(result:, regexes:)
    regexes.each do |regex|
      expect(result).to match(regex)
    end
  end
end

include Beaker::TaskHelper
