require "test_helper"

class Hl7::ParserTest < ActiveSupport::TestCase
  test "parses a single patient with observations" do
    content = <<~HL7
      John Doe|1985-03-15|M|REF-2024-001
      8480-6|120|mmHg
      8310-5|98.6|°F
    HL7

    result = Hl7::Parser.new(content).parse

    assert_equal 1, result.length
    assessment = result.first
    assert_equal "John Doe", assessment.patient_name
    assert_equal Date.new(1985, 3, 15), assessment.dob
    assert_equal "M", assessment.sex_at_birth
    assert_equal "REF-2024-001", assessment.reference
    assert_equal 2, assessment.observations.length
    assert_equal "8480-6", assessment.observations.first.code
    assert_in_delta 120.0, assessment.observations.first.value
    assert_in_delta 98.6, assessment.observations.last.value
  end

  test "parses multiple patients with interspersed headers" do
    content = file_fixture("multiple_patients_hl7.txt").read

    result = Hl7::Parser.new(content).parse

    assert_equal 3, result.length
    assert_equal %w[REF-2024-003 REF-2024-004 REF-2024-005], result.map(&:reference)
    assert_equal [ 1, 2, 2 ], result.map { |a| a.observations.length }
  end

  test "ignores blank lines" do
    content = "John Doe|1985-03-15|M|REF-1\n\n8480-6|120|mmHg\n\n"

    result = Hl7::Parser.new(content).parse

    assert_equal 1, result.first.observations.length
  end

  test "raises on an invalid date" do
    error = assert_raises(Hl7::Parser::Error) do
      Hl7::Parser.new("John Doe|nope|M|REF-1\n8480-6|120|mmHg").parse
    end
    assert_match(/Invalid date/, error.message)
  end

  test "raises on a non-numeric result" do
    error = assert_raises(Hl7::Parser::Error) do
      Hl7::Parser.new("John Doe|1985-03-15|M|REF-1\n8480-6|high|mmHg").parse
    end
    assert_match(/Invalid numeric result/, error.message)
  end

  test "raises when an observation precedes any header" do
    error = assert_raises(Hl7::Parser::Error) do
      Hl7::Parser.new("8480-6|120|mmHg").parse
    end
    assert_match(/before any patient header/, error.message)
  end

  test "raises on a line with the wrong number of fields" do
    error = assert_raises(Hl7::Parser::Error) do
      Hl7::Parser.new("John Doe|1985-03-15|M|REF-1\n8480-6|120").parse
    end
    assert_match(/expected 3 or 4 fields/, error.message)
  end

  test "raises when the file has no records" do
    assert_raises(Hl7::Parser::Error) { Hl7::Parser.new("\n\n").parse }
  end
end
