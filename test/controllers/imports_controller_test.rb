require "test_helper"

class ImportsControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  test "should get new" do
    get new_import_url
    assert_response :success
  end

  test "should get index" do
    Import.create!(filename: "x.txt", content: "data", status: "completed")
    get imports_url
    assert_response :success
  end

  test "create stores the upload, enqueues a job and redirects" do
    file = fixture_file_upload("john_doe_hl7.txt", "text/plain")

    assert_difference -> { Import.count }, 1 do
      assert_enqueued_with(job: ImportJob) do
        post imports_url, params: { file: file }
      end
    end

    import = Import.recent.first
    assert_equal "john_doe_hl7.txt", import.filename
    assert import.pending?
    assert_redirected_to import_url(import)
  end

  test "create without a file redirects back with an alert" do
    assert_no_difference -> { Import.count } do
      post imports_url, params: {}
    end

    assert_redirected_to new_import_url
    assert_equal "Please choose a file to upload.", flash[:alert]
  end

  test "show renders an import" do
    import = Import.create!(filename: "x.txt", content: "data", status: "completed")
    get import_url(import)
    assert_response :success
    assert_match "x.txt", response.body
  end
end
