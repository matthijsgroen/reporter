class Reporter::Field::CountField < Reporter::Field::Base

	def initialize structure, alias_name, data_source, options = {}
		super structure, alias_name
		@source = data_source
		@options = options
	end

	def calculate_value data_source, calculate_options
		source = data_source.get(@source)
		value = source.count options
		Reporter::Value.new(name, options[:name], value, nil, options[:description], options[:source_link])
	end

	private

	attr_reader :options

end