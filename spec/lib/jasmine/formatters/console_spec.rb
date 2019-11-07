# frozen_string_literal: true

require 'spec_helper'

describe Jasmine::Formatters::Console do
  let(:outputter_output) { String.new }
  let(:outputter) do
    double(:outputter).tap do |o|
      allow(o).to receive(:print) { |str| outputter_output << str }
      allow(o).to receive(:puts) { |str| outputter_output << "#{str}\n" }
    end
  end
  let(:run_details) { { 'order' => { 'random' => false } } }

  describe '#format' do
    it 'prints a dot for a successful spec' do
      formatter = Jasmine::Formatters::Console.new(outputter)
      formatter.format([passing_result])

      expect(outputter_output).to include('.')
    end

    it 'prints a star for a pending spec' do
      formatter = Jasmine::Formatters::Console.new(outputter)
      formatter.format([pending_result])

      expect(outputter_output).to include('*')
    end

    it 'prints an F for a failing spec' do
      formatter = Jasmine::Formatters::Console.new(outputter)
      formatter.format([failing_result])

      expect(outputter_output).to include('F')
    end

    it 'prints a dot for a disabled spec' do
      formatter = Jasmine::Formatters::Console.new(outputter)
      formatter.format([disabled_result])

      expect(outputter_output).to eq('')
    end
  end

  describe '#summary' do
    it 'shows the failure messages' do
      results = [failing_result, failing_result]
      formatter = Jasmine::Formatters::Console.new(outputter)
      formatter.format(results)
      formatter.done(run_details)
      expect(outputter_output).to match(/a suite with a failing spec/)
      expect(outputter_output).to match(/a failure message/)
      expect(outputter_output).to match(/a stack trace/)
    end

    describe 'when the full suite passes' do
      it 'shows the spec counts' do
        results = [passing_result]
        console = Jasmine::Formatters::Console.new(outputter)
        console.format(results)
        console.done(run_details)

        expect(outputter_output).to match(/1 spec/)
        expect(outputter_output).to match(/0 failures/)
      end

      it 'shows the spec counts (pluralized)' do
        results = [passing_result, passing_result]
        console = Jasmine::Formatters::Console.new(outputter)
        console.format(results)
        console.done(run_details)

        expect(outputter_output).to match(/2 specs/)
        expect(outputter_output).to match(/0 failures/)
      end
    end

    describe 'when there are failures' do
      it 'shows the spec counts' do
        results = [passing_result, failing_result]
        console = Jasmine::Formatters::Console.new(outputter)
        console.format(results)
        console.done(run_details)

        expect(outputter_output).to match(/2 specs/)
        expect(outputter_output).to match(/1 failure/)
      end

      it 'shows the spec counts (pluralized)' do
        results = [failing_result, failing_result]
        console = Jasmine::Formatters::Console.new(outputter)
        console.format(results)
        console.done(run_details)

        expect(outputter_output).to match(/2 specs/)
        expect(outputter_output).to match(/2 failures/)
      end

      it 'shows the failure message' do
        results = [failing_result]
        console = Jasmine::Formatters::Console.new(outputter)
        console.format(results)
        console.done(run_details)

        expect(outputter_output).to match(/a failure message/)
      end
    end

    describe 'when there are pending specs' do
      it 'shows the spec counts' do
        results = [passing_result, pending_result]
        console = Jasmine::Formatters::Console.new(outputter)
        console.format(results)
        console.done(run_details)

        expect(outputter_output).to match(/1 pending spec/)
      end

      it 'shows the spec counts (pluralized)' do
        results = [pending_result, pending_result]
        console = Jasmine::Formatters::Console.new(outputter)
        console.format(results)
        console.done(run_details)

        expect(outputter_output).to match(/2 pending specs/)
      end

      it 'shows the pending reason' do
        results = [pending_result]
        console = Jasmine::Formatters::Console.new(outputter)
        console.format(results)
        console.done(run_details)

        expect(outputter_output).to match(/I pend because/)
      end

      it 'shows the default pending reason' do
        results = [Jasmine::Result.new(pending_raw_result.merge('pendingReason' => ''))]
        console = Jasmine::Formatters::Console.new(outputter)
        console.format(results)
        console.done(run_details)

        expect(outputter_output).to match(/No reason given/)
      end
    end

    describe 'when there are no pending specs' do
      it 'should not mention pending specs' do
        results = [passing_result]
        console = Jasmine::Formatters::Console.new(outputter)
        console.format(results)
        console.done(run_details)

        expect(outputter_output).to_not match(/pending spec[s]/)
      end
    end

    describe 'when the tests were randomized' do
      it 'should print a message with the seed' do
        results = [passing_result]
        console = Jasmine::Formatters::Console.new(outputter)
        console.format(results)
        console.done({ 'order' => { 'random' => true, 'seed' => '4325' } })

        expect(outputter_output).to match(/Randomized with seed 4325 \(rake jasmine:ci\[true,4325\]\)/)
      end
    end

    describe 'with loading errors' do
      it 'should show the errors' do
        console = Jasmine::Formatters::Console.new(outputter)
        console.done({ 'failedExpectations' => [
          {
            'globalErrorType' => 'load',
            'message' => 'Load Error',
            'stack' => 'more info'
          },
          {
            'globalErrorType' => 'load',
            'message' => 'Another Load Error',
            'stack' => 'even more info'
          },
        ] })

        expect(outputter_output).to match(/Error during loading/)
        expect(outputter_output).to match(/\e\[31mLoad Error\e\[0m\n\s*Stack:\n\s*more info/)
        expect(outputter_output).to match(/\e\[31mAnother Load Error\e\[0m\n\s*Stack:\n\s*even more info/)
      end
    end

    describe 'with errors in a global afterAll' do
      it 'should show the errors' do
        console = Jasmine::Formatters::Console.new(outputter)
        console.done({ 'failedExpectations' => [
          {
            'globalErrorType' => 'afterAll',
            'message' => 'Global Failure',
            'stack' => 'more info'
          },
          {
            'globalErrorType' => 'afterAll',
            'message' => 'Another Failure',
            'stack' => 'even more info'
          },
        ] })

        expect(outputter_output).to match(/Error occurred in afterAll/)
        expect(outputter_output).to match(/\e\[31mGlobal Failure\e\[0m\n\s*Stack:\n\s*more info/)
        expect(outputter_output).to match(/\e\[31mAnother Failure\e\[0m\n\s*Stack:\n\s*even more info/)
      end
    end

    describe 'when the overall status is incomplete' do
      it 'shows the reason' do
        console = Jasmine::Formatters::Console.new(outputter)
        console.done({
          'overallStatus' => 'incomplete',
          'incompleteReason' => 'not all bars were frobnicated'
        })

        expect(outputter_output).to match(/Incomplete: not all bars were frobnicated/)
      end
    end

    it 'shows deprecation warnings' do
      console = Jasmine::Formatters::Console.new(outputter)
      console.format([Jasmine::Result.new(deprecation_raw_result)])
      console.done({ 'deprecationWarnings' => [{ 'message' => 'globally deprecated', 'stack' => nil }] })

      expect(outputter_output).to match(/deprecated call/)
      expect(outputter_output).to match(/globally deprecated/)
    end
  end

  def failing_result
    Jasmine::Result.new(failing_raw_result)
  end

  def passing_result
    Jasmine::Result.new(passing_raw_result)
  end

  def pending_result
    Jasmine::Result.new(pending_raw_result)
  end

  def disabled_result
    Jasmine::Result.new(disabled_raw_result)
  end
end

