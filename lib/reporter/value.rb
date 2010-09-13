class Reporter::Value

	def initialize(field_alias, field_human_name, value, human_value, description, source_link)
		@field_alias = field_alias
		@field_human_name = field_human_name || field_alias
		@value = value
		@human_value = human_value
		@description = description
		@source_link = source_link
	end

	attr_reader :field_alias, :field_human_name
	attr_accessor :value, :description, :source_link
	attr_writer :human_value

	def human_value
		@human_value || value
	end

	def to_s
		human_value
	end

	def as_percentage
		if @value.is_a? Numeric
			"%.2f %%" % (@value * 100.0)
		end
	end

	def round(precision = 2)
		if @value.is_a? Numeric
			"%.#{precision}f" % @value
		end
	end

end