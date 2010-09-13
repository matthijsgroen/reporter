class Reporter::Scope::DateScope < Reporter::Scope::Base

	def initialize scoping, name, mappings
		super scoping, name, mappings
		@period = nil
	end

	def limit= period
		period_as_range = case period
												when Range :
													period.dup
												when Fixnum :
													Date.civil(period).beginning_of_year .. Date.civil(period).end_of_year
											end
		@limit = period_as_range
	end

	def value
		active_period
	end

	def human_name
		active_period.humanize
	end

	def active_period
		get_period || @limit
	end

	def set_period period
		scoping.serialize_scope name, period
	end

	def apply_on source
		raise "No mapped column for source #{source}" unless mappings.has_key? source.name
		column = mappings[source.name]
		source.where(column.to_sym => active_period)
	end

	private

	def get_period
		scoping.unserialize_scope name
	end

end