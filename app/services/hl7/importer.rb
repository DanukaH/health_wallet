module Hl7
  # Imports parsed HL7 lab results into the database, applying the task's
  # find-or-create rules:
  #   Patient     : found by name + dob + sex_at_birth, else created
  #   Assessment  : found by reference within the patient, else created
  #   Observation : found by code within the assessment (value/units updated),
  #                 else created when the code is a known LOINC code.
  class Importer
    Result = Struct.new(:patients, :assessments, :observations, :skipped, keyword_init: true)

    SEX_AT_BIRTH_MAP = { 'M' => 'Male', 'F' => 'Female' }.freeze

    def initialize(content)
      @content = content
      @patients = 0
      @assessments = 0
      @observations = 0
      @skipped = 0
    end

    def call
      Parser.new(@content).parse.each { |parsed| import_assessment(parsed) }

      Result.new(
        patients: @patients,
        assessments: @assessments,
        observations: @observations,
        skipped: @skipped
      )
    end

    private

    def import_assessment(parsed)
      patient = find_or_create_patient(parsed)
      assessment = find_or_create_assessment(patient, parsed.reference)
      parsed.observations.each { |observation| upsert_observation(assessment, observation) }
      assessment.save!
    end

    def find_or_create_patient(parsed)
      attrs = {
        name: parsed.patient_name,
        dob: parsed.dob,
        sex_at_birth: SEX_AT_BIRTH_MAP[parsed.sex_at_birth] }
      existing = Patient.where(attrs).first
      return existing if existing

      @patients += 1
      Patient.create!(attrs)
    end

    def find_or_create_assessment(patient, reference)
      existing = patient.assessments.where(reference: reference).first
      return existing if existing

      @assessments += 1
      patient.assessments.create!(reference: reference)
    end

    def upsert_observation(assessment, parsed)
      existing = assessment.observations.detect { |o| o.code == parsed.code }

      if existing
        existing.assign_attributes(value: parsed.value, units: parsed.units)
        @observations += 1
      elsif Loinc.known?(parsed.code)
        assessment.observations.build(
          code: parsed.code,
          name: Loinc.description(parsed.code),
          value: parsed.value,
          units: parsed.units
        )
        @observations += 1
      else
        @skipped += 1
      end
    end
  end
end
