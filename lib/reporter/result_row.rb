class Reporter::ResultRow

	def initialize(data_set, scope_serialization)
		@data_set = data_set
		@scope_serialization = scope_serialization
		@field_cache = { }
	end

	def [] field
		field_cache[field] ||= load_field_values(field)[field]
	end

	protected

	attr_reader :data_set, :scope_serialization
	attr_accessor :field_cache

	def load_field_values(*fields)
		execute_fields *(fields + [{ :scope => scope_serialization, :row => self }])
	end

	def execute_fields *fields
		options = fields.extract_options!
		temp_scope = data_set.data_source.scopes.current_scope
		field_options = {}
		data_set.data_source.scopes.apply_scope options[:scope] if options[:scope]
		field_options[:row] = options[:row] if options[:row]
		results = {}
		fields.each do |field|
			results[field] = data_set.data_structure.field_value_of field, field_options
		end
		data_set.data_source.scopes.apply_scope temp_scope
		results
	end


end