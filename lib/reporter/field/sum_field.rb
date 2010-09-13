class Reporter::Field::SumField < Reporter::Field::Base

	def initialize structure, alias_name, name, data_source, column, options = {}
		super structure, alias_name, name
		@source = data_source
		@column = column
		@options = options
	end

	def calculate_value data_source, calculation_options
		source = data_source.get(@source)
		value = source.sum @column, options
		Reporter::Value.new(name, human_name, value, nil, options[:description], options[:source_link])
	end

	private

	attr_reader :options
end