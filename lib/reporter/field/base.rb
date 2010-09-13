class Reporter::Field::Base

	def initialize structure, alias_name, name
		@structure = structure
		@human_name = name
		@name = alias_name
	end

	def validate
		raise NotImplementedError
	end

	def calculate_value data_source, options
		raise NotImplementedError
	end

	attr_reader :name, :human_name

	protected
	attr_reader :structure

end