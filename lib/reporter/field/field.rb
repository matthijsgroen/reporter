class Reporter::Field::Field < Reporter::Field::Base

	def initialize structure, alias_name, name, *args, &block
		super structure, alias_name, name
		@options = args.extract_options!
		@value = args.first
		@calculation_block = block if block_given?
	end

	def calculate_value data_source, options
		if @calculation_block
			row = Reporter::Value.new(name, human_name, nil, nil, options[:description], options[:source_link])
			@calculation_block.call(data_source, options, row)
			return row
		end
		return Reporter::Value.new(name, human_name, value, nil, options[:description], options[:source_link]) unless value.is_a? Symbol
		Reporter::Value.new(name, human_name, data_source.scopes.get(value).value,
												data_source.scopes.get(value).human_name, options[:description], options[:source_link])
	end

	private

	attr_reader :options, :value

end