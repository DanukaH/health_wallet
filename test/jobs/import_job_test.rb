require "test_helper"

class ImportJobTest < ActiveJob::TestCase
  test "processes the import and records completed status with counts" do
    import = Import.create!(
      filename: "john.txt",
      content: file_fixture("john_doe_hl7.txt").read
    )

    ImportJob.perform_now(import.id.to_s)
    import.reload

    assert import.completed?
    assert_equal 1, import.patients_imported
    assert_equal 1, import.assessments_imported
    assert_equal 4, import.observations_imported
    assert_nil import.error_message
  end

  test "records failed status and error message on invalid input" do
    import = Import.create!(
      filename: "bad.txt",
      content: file_fixture("invalid_hl7.txt").read
    )

    ImportJob.perform_now(import.id.to_s)
    import.reload

    assert import.failed?
    assert_match(/Invalid date/, import.error_message)
  end
end
