require 'spec_helper_acceptance'

RSpec.describe Beaker::TaskHelper do
  it 'returns correct summary line' do
    describe 'with default values' do
      expect(task_summary_line).to be 'Job completed. 1/1 nodes succeeded|Ran on 1 node'
    end
    describe 'with 3 total hosts and 2 success' do
      expect(task_summary_line(3, 2)).to be 'Job completed. 2/3 nodes succeeded|Ran on 3 node'
    end
  end
end
