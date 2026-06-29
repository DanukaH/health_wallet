require "test_helper"

class Hl7::ImporterTest < ActiveSupport::TestCase
  test "creates patient, assessment and observations" do
    content = file_fixture("john_doe_hl7.txt").read

    result = Hl7::Importer.new(content).call

    assert_equal 1, result.patients
    assert_equal 1, result.assessments
    assert_equal 4, result.observations
    assert_equal 0, result.skipped

    patient = Patient.find_by(name: "John Doe", dob: Date.new(1985, 3, 15), sex_at_birth: "Male")
    assessment = patient.assessments.find_by(reference: "REF-2024-001")
    systolic = assessment.observations.detect { |o| o.code == "8480-6" }
    assert_equal "Blood Pressure (Systolic)", systolic.name
    assert_in_delta 120.0, systolic.value
    assert_equal "mmHg", systolic.units
  end

  test "is idempotent and updates values without duplicating records" do
    content = file_fixture("john_doe_hl7.txt").read
    Hl7::Importer.new(content).call

    updated = content.sub("8480-6|120|mmHg", "8480-6|130|mmHg")
    result = Hl7::Importer.new(updated).call

    assert_equal 0, result.patients
    assert_equal 0, result.assessments
    assert_equal 1, Patient.where(name: "John Doe").count
    assert_equal 1, Patient.find_by(name: "John Doe").assessments.where(reference: "REF-2024-001").count

    assessment = Patient.find_by(name: "John Doe").assessments.find_by(reference: "REF-2024-001")
    assert_equal 4, assessment.observations.count
    assert_in_delta 130.0, assessment.observations.detect { |o| o.code == "8480-6" }.value
  end

  test "skips observations with unknown codes that do not already exist" do
    content = "John Doe|1985-03-15|M|REF-1\n0000-0|42|x\n8480-6|120|mmHg\n"

    result = Hl7::Importer.new(content).call

    assert_equal 1, result.observations
    assert_equal 1, result.skipped
    assessment = Patient.find_by(name: "John Doe").assessments.find_by(reference: "REF-1")
    assert_nil assessment.observations.detect { |o| o.code == "0000-0" }
  end

  test "imports multiple patients from one file" do
    content = file_fixture("multiple_patients_hl7.txt").read

    result = Hl7::Importer.new(content).call

    assert_equal 3, result.patients
    assert_equal 3, result.assessments
    assert_equal 5, result.observations
    assert_equal 3, Patient.count
  end
end
