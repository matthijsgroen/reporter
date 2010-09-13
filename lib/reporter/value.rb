class Reporter::Value

	def initialize(field_alias, field_human_name, value, human_value, description, source_link)
		@field_alias = field_alias
		@field_human_name = field_human_name || field_alias
		@value = value
		@human_value = human_value || value
		@description = description
		@source_link = source_link
	end

	attr_reader :field_alias, :field_human_name, :value, :human_value, :description, :source_link

	def to_s
		human_value
	end

	def as_percentage
		if @value.is_a? Numeric
			"%.2f %%" % (@value * 100.0)
		end
	end

end