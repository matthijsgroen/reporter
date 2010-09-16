class Reporter::Field::CountField < Reporter::Field::CalculationField

	def initialize structure, alias_name, data_source, *args, &block
		options = args.extract_options!
		column = args.first
		super structure, alias_name, data_source, :count, column, options, &block
	end

end