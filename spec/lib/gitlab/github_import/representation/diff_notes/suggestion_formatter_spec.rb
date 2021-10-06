# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Representation::DiffNotes::SuggestionFormatter do
  it 'does nothing when there is any text before the suggestion tag' do
    note = <<~BODY
    looks like```suggestion but it isn't
    ```
    BODY

    expect(described_class.formatted_note_for(note: note)).to eq(note)
  end

  it 'handles nil value for note' do
    note = nil

    expect(described_class.formatted_note_for(note: note)).to eq(note)
  end

  it 'does not allow over 3 leading spaces for valid suggestion' do
    note = <<~BODY
      Single-line suggestion
          ```suggestion
      sug1
      ```
    BODY

    expect(described_class.formatted_note_for(note: note)).to eq(note)
  end

  it 'allows up to 3 leading spaces' do
    note = <<~BODY
      Single-line suggestion
         ```suggestion
      sug1
      ```
    BODY

    expected = <<~BODY
      Single-line suggestion
      ```suggestion:-0+0
      sug1
      ```
    BODY

    expect(described_class.formatted_note_for(note: note)).to eq(expected)
  end

  it 'does nothing when there is any text without space after the suggestion tag' do
    note = <<~BODY
    ```suggestionbut it isn't
    ```
    BODY

    expect(described_class.formatted_note_for(note: note)).to eq(note)
  end

  it 'formats single-line suggestions' do
    note = <<~BODY
      Single-line suggestion
      ```suggestion
      sug1
      ```
    BODY

    expected = <<~BODY
      Single-line suggestion
      ```suggestion:-0+0
      sug1
      ```
    BODY

    expect(described_class.formatted_note_for(note: note)).to eq(expected)
  end

  it 'ignores text after suggestion tag on the same line' do
    note = <<~BODY
    looks like
    ```suggestion text to be ignored
    suggestion
    ```
    BODY

    expected = <<~BODY
    looks like
    ```suggestion:-0+0
    suggestion
    ```
    BODY

    expect(described_class.formatted_note_for(note: note)).to eq(expected)
  end

  it 'formats multiple single-line suggestions' do
    note = <<~BODY
      Single-line suggestion
      ```suggestion
      sug1
      ```
      OR
      ```suggestion
      sug2
      ```
    BODY

    expected = <<~BODY
      Single-line suggestion
      ```suggestion:-0+0
      sug1
      ```
      OR
      ```suggestion:-0+0
      sug2
      ```
    BODY

    expect(described_class.formatted_note_for(note: note)).to eq(expected)
  end

  it 'formats multi-line suggestions' do
    note = <<~BODY
      Multi-line suggestion
      ```suggestion
      sug1
      ```
    BODY

    expected = <<~BODY
      Multi-line suggestion
      ```suggestion:-2+0
      sug1
      ```
    BODY

    expect(described_class.formatted_note_for(note: note, start_line: 6, end_line: 8)).to eq(expected)
  end

  it 'formats multiple multi-line suggestions' do
    note = <<~BODY
      Multi-line suggestion
      ```suggestion
      sug1
      ```
      OR
      ```suggestion
      sug2
      ```
    BODY

    expected = <<~BODY
      Multi-line suggestion
      ```suggestion:-2+0
      sug1
      ```
      OR
      ```suggestion:-2+0
      sug2
      ```
    BODY

    expect(described_class.formatted_note_for(note: note, start_line: 6, end_line: 8)).to eq(expected)
  end
end
