class Reporter::Field::SumField < Reporter::Field::CalculationField

	def initialize structure, alias_name, data_source, column, options = {}, &block
		super structure, alias_name, data_source, :sum, column, options, &block
	end

end