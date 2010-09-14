class Reporter::Field::Field < Reporter::Field::Base

	def initialize structure, alias_name, *args, &block
		super structure, alias_name
		@options = args.extract_options!
		@value = args.first
		@calculation_block = block if block_given?
	end

	def calculate_value data_source, calculation_options
		if @calculation_block
			row = Reporter::Value.new(name, options[:name], nil, nil, options[:description], options[:source_link])
			@calculation_block.call(data_source, options, row)
			return row
		end
		return Reporter::Value.new(name, options[:name], value, nil, options[:description], options[:source_link]) unless value.is_a? Symbol
		Reporter::Value.new(name, options[:name], data_source.scopes.get(value).value,
												data_source.scopes.get(value).human_name, options[:description], options[:source_link])
	end

	private

	attr_reader :options, :value

end