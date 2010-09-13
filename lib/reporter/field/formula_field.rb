class Reporter::Field::FormulaField < Reporter::Field::Base

	def initialize structure, alias_name, name, formula, options = {}
		super structure, alias_name, name
		@formula = Reporter::Formula.new formula
		@options = options
	end

	def calculate_value data_source, options
		required_terms = {}
		formula.term_list.each do |term|
			required_terms[term] = nil
			required_terms[term] = options[:row][term].value if options[:row] and term != name
		end
		value = formula.call(required_terms)

		Reporter::Value.new(name, human_name, value, nil, options[:description], options[:source_link])
	end

	private

	attr_reader :options, :formula

end