require 'beaker'

# Beaker task Helper
module Beaker::TaskHelper # rubocop:disable Style/ClassAndModuleChildren
  include Beaker::DSL

  def puppet_version
    (on default, puppet('--version')).output.chomp
  end

  DEFAULT_PASSWORD = if default[:hypervisor] == 'vagrant'
                       'puppet'
                     elsif default[:hypervisor] == 'vcloud' || default[:hypervisor] == 'vmpooler'
                       'Qu@lity!'
                     else
                       'root'
                     end

  BOLT_VERSION = '0.7.0'.freeze

  def install_bolt_on(hosts, version = BOLT_VERSION, source = nil)
    unless default[:docker_image_commands].nil?
      if default[:docker_image_commands].to_s.include? 'yum'
        on(hosts, 'yum install -y make gcc ruby-devel', acceptable_exit_codes: [0, 1]).stdout
      elsif default[:docker_image_commands].to_s.include? 'apt-get'
        on(hosts, 'apt-get install -y make gcc ruby-dev', acceptable_exit_codes: [0, 1]).stdout
      end

    end

    Array(hosts).each do |host|
      pp = <<-INSTALL_BOLT_PP
  package { 'bolt' :
    provider => 'puppet_gem',
    ensure   => '#{version}',
INSTALL_BOLT_PP
      pp << "source   => '#{source}'" if source
      pp << '}'
      apply_manifest_on(host, pp)
    end
  end

  def pe_install?
    ENV['PUPPET_INSTALL_TYPE'] =~ %r{pe}i
  end

  def run_puppet_access_login(user:, password: '~!@#$%^*-/ aZ', lifetime: '5y')
    on(master, puppet('access', 'login', '--username', user, '--lifetime', lifetime), stdin: password)
  end

  def run_task(task_name:, params: nil, password: DEFAULT_PASSWORD, format: 'human')
    output = if pe_install?
               run_puppet_task(task_name: task_name, params: params)
             else
               run_bolt_task(task_name: task_name, params: params, password: password)
             end

    if format == 'json'
      output = JSON.parse(output)
      output['items'][0]
    else
      output
    end
  end

  def run_bolt_task(task_name:, params: nil, password: DEFAULT_PASSWORD, host: 'localhost', format: 'human') # rubocop:disable Metrics/LineLength, Lint/UnusedMethodArgument
    if fact_on(default, 'osfamily') == 'windows'
      bolt_path = '/cygdrive/c/Program\ Files/Puppet\ Labs/Puppet/sys/ruby/bin/bolt.bat'
      module_path = 'C:/ProgramData/PuppetLabs/code/modules'
    else
      bolt_path = '/opt/puppetlabs/puppet/bin/bolt'
      module_path = '/etc/puppetlabs/code/modules'
    end
    bolt_full_cli = "#{bolt_path} task run #{task_name} --insecure -m #{module_path} --nodes #{host} --password #{password}" # rubocop:disable Metrics/LineLength
    bolt_full_cli << if params.class == Hash
                       " --params '#{params.to_json}'"
                     else
                       " #{params}"
                     end
    # windows is special
    if fact_on(default, 'osfamily') == 'windows'
      bolt_full_cli << ' --transport winrm --user Administrator'
    end
    puts "BOLT_CLI: #{bolt_full_cli}" if ENV['BEAKER_debug']
    on(default, bolt_full_cli, acceptable_exit_codes: [0, 1]).stdout
  end

  def run_puppet_task(task_name:, params: nil, host: 'localhost', format: 'human')
    args = ['task', 'run', task_name, '--nodes', host]
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
