class Reporter::TimeOptimizedResultRow < Reporter::ResultRow

	def initialize(data_set, scope_serialization, scope, period)
		super data_set, scope_serialization
		@scope = scope
		@period = period
		@active_scope = nil
	end

	attr_accessor :current_iteration

	def scope= scope
		@scope_serialization = scope
	end

	def [] field
		field_cache[field] ||= {}
		preload_time_period_values_for field unless field_cache[field].has_key? current_iteration[:type]
		field_cache[field][current_iteration[:type]] ||= {}
		field_cache[field][current_iteration[:type]][current_iteration[:period]] ||= load_field_values(field)[field]
	end

	private

	attr_reader :data_set, :scope_serialization, :period

	def preload_time_period_values_for(field_name)
		#Rails.logger.info "Trying to pre-load data for #{field_name} for the period of #{period} in chunks of #{current_iteration[:filter].to_sentence}"

		field = data_set.data_structure.fields[field_name]
		if field.respond_to? :preload_for_period
			#Rails.logger.info "Preloading possible for #{field_name}!"
			field_cache[field_name] ||= {}
			field_cache[field_name][current_iteration[:type]] = \
				field.preload_for_period data_set.data_source, {}, period, current_iteration[:filter], @scope
		end
	end

end