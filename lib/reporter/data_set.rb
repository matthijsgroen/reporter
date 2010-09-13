require "reporter/support/time_range"

class Reporter::DataSet

	def initialize *args
		@row_structure = nil
		@axis_values = {}

		@row_cache = {}
		yield self if block_given?
	end

	def data_source= value
		@data_source = value
	end

	attr_reader :data_source

	def data_structure *args, &block
		@data_structure = Reporter::DataStructure.new self, *args, &block
	end

	def get_row
		current_scope = data_source.scopes.current_scope
		@row_cache[current_scope.hash] ||= Reporter::ResultRow.new(self, current_scope)
	end

	def execute_fields *fields
		options = fields.extract_options!
		temp_scope = data_source.scopes.current_scope
		field_options = {}
		data_source.scopes.apply_scope options[:scope] if options[:scope]
		field_options[:row] = options[:row] if options[:row]
		results = {}
		fields.each do |field|
			results[field] = @data_structure.field_value_of field, field_options
		end
		data_source.scopes.apply_scope temp_scope
		results
	end

	def iterate scope, items = nil, &block
		raise "No data-source set" unless data_source
		data_source.scopes.get(scope).iterate items, &block
	end

	def scope_name scope
		raise "No data-source set" unless data_source
		data_source.scopes.get(scope).human_name
	end

	include Reporter::TimeIterator

end