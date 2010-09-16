class Reporter::Field::AverageField < Reporter::Field::CalculationField

	def initialize structure, alias_name, data_source, column, options = {}, &block
		super structure, alias_name, data_source, :average, column, options, &block
	end

end