require 'test_helper'

class GovukContentSchemaTest < ActiveSupport::TestCase

  test "GovukContentSchema.schema_path returns a path to the matching schema" do
    schema_path = GovukContentSchema.schema_path(schema_name)
    schema = File.read(schema_path)

    assert_is_json(schema)
    assert_equal "Test schema", JSON.parse(schema)["title"]
  end

  test "GovukContentSchema.schema_path returns nil if not a valid schema name" do
    schema_name = 'invalid'
    schema_path = GovukContentSchema.schema_path(schema_name)

    assert_nil schema_path
  end

  test "Validator#valid returns true for valid JSON" do
    validator = GovukContentSchema::Validator.new(schema_name, valid_json)

    assert validator.valid?
  end

  test "Validator#valid returns false for invalid JSON" do
    invalid_json = valid_json(number: 'not a number')
    validator = GovukContentSchema::Validator.new(schema_name, invalid_json)

    refute validator.valid?
  end

  test "Validator#errors returns errors for invalid JSON" do
    invalid_json = valid_json(number: 'not a number')
    validator = GovukContentSchema::Validator.new(schema_name, invalid_json)

    assert_equal 1, validator.errors.size
    assert_match /number/, validator.errors[0]
  end

  test "#schema_path uses env variable for valid schema names" do
    ENV.stubs(:[]).with('GOVUK_CONTENT_SCHEMAS_PATH').returns('/foo/bar/baz')
    schema_name = 'case_study'
    schema_path = GovukContentSchema.schema_path(schema_name)
    assert_equal '/foo/bar/baz/formats/case_study/publisher/schema.json', schema_path
  end

  test "Validator.new raises error if schema file not found" do
    ENV.stubs(:[]).with('GOVUK_CONTENT_SCHEMAS_PATH').returns('/foo/bar/baz')
    assert_raises GovukContentSchema::ImproperlyConfiguredError do
      GovukContentSchema::Validator.new('case_study', valid_json)
    end
  end

private

  def schema_name
    'test'
  end

  def valid_json(overrides={})
    {
      name: 'foobar',
      number: 12
    }.merge(overrides).to_json
  end

  def assert_is_json(json)
    assert begin
      !!JSON.parse(json)
    rescue JSON::ParserError
      false
    end, "string is not valid JSON"
  end
end
