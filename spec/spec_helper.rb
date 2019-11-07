# frozen_string_literal: true

require 'rubygems'
require 'bundler'
require 'stringio'
require 'tmpdir'

envs = %i[default development]
envs << :debug if ENV['DEBUG']
Bundler.setup(*envs)

$LOAD_PATH.unshift(File.expand_path(File.join(File.dirname(__FILE__), '../lib')))
require 'jasmine'
require 'rspec'

def create_temp_dir
  tmp = File.join(Dir.tmpdir, "jasmine-gem-test_#{Time.now.to_f}")
  FileUtils.rm_r(tmp, force: true)
  FileUtils.mkdir(tmp)
  tmp
end

def temp_dir_before
  @root = File.expand_path(File.join(File.dirname(__FILE__), '..'))
  @old_dir = Dir.pwd
  @tmp = create_temp_dir
end

def temp_dir_after
  Dir.chdir @old_dir
  FileUtils.rm_r @tmp
end

module Kernel
  def capture_stdout
    out = StringIO.new
    $stdout = out
    yield
    out.string
  ensure
    $stdout = STDOUT
  end
end

def passing_raw_result
  {
    'id' => 123,
    'status' => 'passed',
    'fullName' => 'Passing test',
    'description' => 'Passing',
    'failedExpectations' => [],
    'deprecationWarnings' => []
  }
end

def pending_raw_result
  {
    'id' => 123,
    'status' => 'pending',
    'fullName' => 'Passing test',
    'description' => 'Pending',
    'failedExpectations' => [],
    'pendingReason' => 'I pend because',
    'deprecationWarnings' => []
  }
end

def disabled_raw_result
  {
    'id' => 123,
    'status' => 'disabled',
    'fullName' => 'Disabled test',
    'description' => 'Disabled',
    'failedExpectations' => [],
    'deprecationWarnings' => []
  }
end

def failing_raw_result
  {
    'status' => 'failed',
    'id' => 124,
    'description' => 'a failing spec',
    'fullName' => 'a suite with a failing spec',
    'failedExpectations' => [
      {
        'message' => 'a failure message',
        'stack' => 'a stack trace'
      }
    ],
    'deprecationWarnings' => []
  }
end

def failing_result_no_stack_trace
  {
    'status' => 'failed',
    'id' => 124,
    'description' => 'a failing spec',
    'fullName' => 'a suite with a failing spec',
    'failedExpectations' => [
      {
        'message' => 'a failure message, but no stack',
        'stack' => nil
      }
    ],
    'deprecationWarnings' => []
  }
end

def deprecation_raw_result
  {
    'id' => 123,
    'status' => 'passed',
    'fullName' => 'test with deprecated calls',
    'description' => 'Deprecations',
    'failedExpectations' => [],
    'deprecationWarnings' => [{
      'message' => 'deprecated call'
    }]
  }
end

