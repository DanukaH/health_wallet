require "test_helper"

class ImportTest < ActiveSupport::TestCase
  test "defaults to pending status with zeroed counters" do
    import = Import.create!(filename: "x.txt", content: "data")

    assert import.pending?
    assert_equal 0, import.patients_imported
    assert_equal 0, import.observations_skipped
  end

  test "rejects an unknown status" do
    import = Import.new(filename: "x.txt", content: "data", status: "bogus")

    assert_not import.valid?
    assert_includes import.errors[:status], "is not included in the list"
  end

  test "status predicates reflect the status field" do
    import = Import.new(status: "completed")

    assert import.completed?
    assert_not import.failed?
  end
end
