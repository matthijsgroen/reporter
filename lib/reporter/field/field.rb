class Reporter::Field::Field < Reporter::Field::Base

	def initialize structure, alias_name, name, value, options = {}
		super structure, alias_name, name
		@value = value
		@options = options
	end

	def calculate_value data_source, options
		return Reporter::Value.new(name, human_name, value, nil, options[:description], options[:source_link]) unless value.is_a? Symbol
		Reporter::Value.new(name, human_name, data_source.scopes.get(value).value,
												data_source.scopes.get(value).human_name, options[:description], options[:source_link])
	end

	private

	attr_reader :options, :value

end