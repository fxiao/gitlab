# frozen_string_literal: true

require 'spec_helper'
require 'rubocop'
require_relative '../../rubocop/qa_helpers'

RSpec.describe RuboCop::QAHelpers do
  def parse_source(source, path = 'foo.rb')
    buffer = Parser::Source::Buffer.new(path)
    buffer.source = source

    builder = RuboCop::AST::Builder.new
    parser = Parser::CurrentRuby.new(builder)

    parser.parse(buffer)
  end

  let(:cop) do
    Class.new do
      include RuboCop::QAHelpers
    end.new
  end

  describe '#in_qa_file?' do
    it 'returns true for a node in the qa/ directory' do
      node = parse_source('10', Rails.root.join('qa', 'qa', 'page', 'dashboard', 'groups.rb'))

      expect(cop.in_qa_file?(node)).to eq(true)
    end

    it 'returns false for a node outside the qa/ directory' do
      node = parse_source('10', Rails.root.join('app', 'foo', 'foo.rb'))

      expect(cop.in_qa_file?(node)).to eq(false)
    end
  end
end
