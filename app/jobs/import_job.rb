class ImportJob < ApplicationJob
  queue_as :default

  def perform(import_id)
    import = Import.find(import_id)
    import.update!(status: "processing")

    result = Hl7::Importer.new(import.content).call

    import.update!(
      status: "completed",
      error_message: nil,
      patients_imported: result.patients,
      assessments_imported: result.assessments,
      observations_imported: result.observations,
      observations_skipped: result.skipped
    )
  rescue StandardError => e
    # The Import record is the user-facing error channel, so we record the
    # failure there rather than re-raising and producing noisy async backtraces.
    import&.update(status: "failed", error_message: e.message)
  end
end
