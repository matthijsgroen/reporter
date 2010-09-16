class Reporter::Field::CalculationField < Reporter::Field::Base

	def initialize structure, alias_name, data_source, calculation, column, options = {}, &block
		super structure, alias_name
		@source = data_source
		@column = column
		@options = options
		@calculation = calculation
		@calculation_block = block if block_given?
	end

	def calculate_value data_source, calculation_options
		source = data_source.get(@source)
		value = source.calculate @calculation, @column, options, &calculation_block
		Reporter::Value.new(name, options[:name], value, nil, options[:description], options[:source_link])
	end

	def preload_for_period data_source, calculation_options, period, filter, scope
		source = data_source.get(@source)
		values = source.calculate_for_period @calculation, period, filter, scope, @column, options, &calculation_block
		results = {}
		values.each do |r|
			val = r.delete :value
			results[r] = Reporter::Value.new(name, options[:name], val, nil, options[:description], options[:source_link])
		end
		results
	end

	private

	attr_reader :options, :calculation_block
end