module Hl7
  # LOINC codes recognised by the importer, mapped to their human-readable
  # description. Observations whose code is not listed here are only imported
  # when they already exist on the assessment (see Hl7::Importer).
  module Loinc
    CODES = {
      "8480-6" => "Blood Pressure (Systolic)",
      "8462-4" => "Blood Pressure (Diastolic)",
      "8867-4" => "Heart Rate",
      "8310-5" => "Body Temperature",
      "9279-1" => "Respiratory Rate",
      "2708-6" => "Oxygen Saturation",
      "29463-7" => "Body Weight",
      "8302-2" => "Body Height",
      "2339-0" => "Blood Glucose",
      "2093-3" => "Cholesterol"
    }.freeze

    def self.known?(code)
      CODES.key?(code)
    end

    def self.description(code)
      CODES[code]
    end
  end
end
