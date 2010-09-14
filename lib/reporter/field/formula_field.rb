class Reporter::Field::FormulaField < Reporter::Field::Base

	def initialize structure, alias_name, formula, options = {}
		super structure, alias_name
		@formula = Reporter::Formula.new formula
		@options = options
	end

	def calculate_value data_source, calculation_options
		required_terms = {}
		formula.term_list.each do |term|
			required_terms[term] = nil
			required_terms[term] = calculation_options[:row][term].value if calculation_options[:row] and term != name
		end
		value = formula.call(required_terms)

		Reporter::Value.new(name, options[:name], value, nil, options[:description], options[:source_link])
	end

	private

	attr_reader :options, :formula

end