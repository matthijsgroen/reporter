class Reporter::ResultRow

	def initialize(data_set, scope_serialization)
		@data_set = data_set
		@scope_serialization = scope_serialization
		@field_cache = { }
	end

	def [] field
		@field_cache[field] ||= load_field_values(field)[field]
	end

	private

	attr_reader :data_set, :scope_serialization

	def load_field_values(*fields)
		data_set.execute_fields *(fields + [{ :scope => scope_serialization, :row => self }])
	end


end