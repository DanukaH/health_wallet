class ImportsController < ApplicationController
  def index
    @imports = Import.recent
  end

  def show
    @import = Import.find(params[:id])
  end

  def new
  end

  def create
    file = params[:file]

    if file.blank?
      redirect_to new_import_path, alert: "Please choose a file to upload."
      return
    end

    import = Import.create!(
      filename: file.original_filename,
      content: file.read.force_encoding(Encoding::UTF_8),
      status: "pending"
    )

    ImportJob.perform_later(import.id.to_s)

    redirect_to import_path(import), notice: "File uploaded. Import is being processed."
  end
end
