class Reporter::Scope::DateScope < Reporter::Scope::Base

	def initialize scoping, name, data_source, mappings
		super scoping, name, data_source, mappings
		@period = nil
	end

	def limit= period
		@limit = period_as_range(period)
	end

	def value
		active_period
	end

	def human_name
		active_period.human_name
	end

	def active_period
		get_period || @limit
	end

	def change period
		scoping.serialize_scope name, period_as_range(period)
	end

	def apply_on source, period = nil
		raise "No mapped column for source #{source}" unless mappings.has_key? source.name
		column = mappings[source.name]
		# The time period range is inclusive in all aspects of the report to detemine correctly if it runs to the end of a year
		# or the beginning of another year.
		# In SQL, the period is used as a BETWEEN statement, with the end exclusive.
		# In code when we want the whole of Januari, we use 1-1 00:00 till 1-31 23:59
		# in SQL, we need to use BETWEEN 1-1 00:00 AND 2-1 00:00
		# when a date includes time, we need to add 1 second. If a date has no time, we need to include 1 day.

		period ||= active_period.dup
		period = if period.end.is_a? Date
			period.begin .. period.end.advance(:days => 1)
	  else
			period.begin .. period.end.advance(:seconds => 1)
		end

		case column
			when String :
				source.where(column.to_sym => period)
  		when Hash : begin
				column.each do |key, value|
					source = source.joins(key).where(key => { value => period })
				end
				source
			end
		end
	end

	def group_on source, period_type
		column = mappings[source.name]
		case column
			when String :
				"#{period_type.to_s.upcase}(#{column})"
			when Hash : begin
				column.each do |key, value|
					table_name = table_name_of_association source, key
					return "#{period_type.to_s.upcase}(#{table_name}.#{value})"
				end
			end
		end
	end

	def self.possible_scopes sources
		results = []
		global_dates = nil
		specific_dates = { :type => :date, :match => :loose }
		sources.each do |source|
			global_dates = global_dates ? (global_dates & source.date_columns) : source.date_columns
			specific_dates[source.model_name] = source.date_columns
		end
		results << specific_dates
		global_dates.each do |reference|
			result_hash = {:type => :date, :match => :exact}
			sources.each { |source| result_hash[source.model_name] = reference }
			results << result_hash
		end if global_dates
		results
	end

	private

	def get_period
		scoping.unserialize_scope name
	end

	def period_as_range period
		case period
			when Range :
				period.dup
			when Fixnum :
				Date.civil(period).beginning_of_year .. Date.civil(period).end_of_year
			when :year_cumulative :
				active_period.begin.beginning_of_year .. active_period.end
		end
	end

	def table_name_of_association source, name
		source.reflect_on_association(name.to_sym).klass.table_name
	end

end