class Reporter::DataStructure

	def initialize data_set, *args, &block
		@data_set = data_set
		@fields = {}
		yield(self)
	end

	attr_reader :fields

	def << column_type, column_alias, *args, &block
		klass = "reporter/field/#{column_type}".classify.constantize
		column = klass.new self, column_alias, *args, &block
		#TODO: Validate column

		@fields[column_alias] = column
		column
	end
	alias :add :<<

	def field_value_of field, options
		raise "No such field defined" unless @fields.has_key? field
		@fields[field].calculate_value(data_set.data_source, options)
	end

	def method_missing(method_name, *args, &block)
		if method_name.to_s =~ /^add_(.*)_field$/
			return send :add, "#{$1}_field", *args, &block
		end
		return send :add, :field, *args, &block if method_name.to_s == "add_field"
		super
	end

	def respond_to?(method_name)
		return true if method_name.to_s.starts_with? "add_" and method_name.to_s.ends_with? "_field"
		super
	end

	private

	attr_reader :data_set
end
