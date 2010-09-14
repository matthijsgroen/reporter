class Reporter::Field::Base

	def initialize structure, alias_name
		@structure = structure
		@name = alias_name
	end

	def validate
		raise NotImplementedError
	end

	def calculate_value data_source, options
		raise NotImplementedError
	end

	attr_reader :name

	protected
	attr_reader :structure

end