module Hl7
  # Parses the simplified HL7 lab-result format into structured data.
  #
  # The format is line based, fields separated by "|":
  #   patient_name|patient_dob|patient_sex_at_birth|assessment_reference  (4 fields = header)
  #   code|result|units                                                  (3 fields = observation)
  #
  # A single file may contain several headers, each followed by its own
  # observation lines (see Multiple_Patients_HL7.txt in the task).
  class Parser
    class Error < StandardError; end

    ParsedAssessment = Struct.new(:patient_name, :dob, :sex_at_birth, :reference, :observations, keyword_init: true)
    ParsedObservation = Struct.new(:code, :value, :units, keyword_init: true)

    def initialize(content)
      @content = content.to_s
    end

    # Returns an Array of ParsedAssessment. Raises Parser::Error on malformed input.
    def parse
      assessments = []
      current = nil

      each_line do |fields, line_number, raw|
        case fields.length
        when 4
          current = build_assessment(fields, line_number)
          assessments << current
        when 3
          raise Error, "Observation on line #{line_number} appears before any patient header: #{raw.inspect}" if current.nil?

          current.observations << build_observation(fields, line_number)
        else
          raise Error, "Malformed line #{line_number}: expected 3 or 4 fields, got #{fields.length}: #{raw.inspect}"
        end
      end

      raise Error, "No valid records found in file" if assessments.empty?

      assessments
    end

    private

    def each_line
      @content.each_line.with_index(1) do |raw, line_number|
        line = raw.strip
        next if line.empty?

        yield line.split("|", -1).map(&:strip), line_number, line
      end
    end

    def build_assessment(fields, line_number)
      name, dob, sex, reference = fields
      raise Error, "Missing patient name on line #{line_number}" if name.empty?
      raise Error, "Missing assessment reference on line #{line_number}" if reference.empty?

      ParsedAssessment.new(
        patient_name: name,
        dob: parse_date(dob, line_number),
        sex_at_birth: sex,
        reference: reference,
        observations: []
      )
    end

    def build_observation(fields, line_number)
      code, value, units = fields
      raise Error, "Missing observation code on line #{line_number}" if code.empty?

      ParsedObservation.new(
        code: code,
        value: parse_value(value, line_number),
        units: units
      )
    end

    def parse_date(value, line_number)
      Date.iso8601(value)
    rescue ArgumentError, TypeError
      raise Error, "Invalid date #{value.inspect} on line #{line_number} (expected YYYY-MM-DD)"
    end

    def parse_value(value, line_number)
      Float(value)
    rescue ArgumentError, TypeError
      raise Error, "Invalid numeric result #{value.inspect} on line #{line_number}"
    end
  end
end
