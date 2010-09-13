class Reporter::DataSource::Scoping

	def initialize data_source
		@data_source = data_source
		@defined_scopes = {}
		@scope_serialization = {}
	end

	public

	def possible
		return @possible_scopes if @possible_scopes
		results = []
		results += possible_reference_scopes
		results += possible_time_scopes
		#[{ :funeral => "work_area", :cbs_statistic => "work_area" }, { :funeral => "notification_date", :cbs_statistic => "month" }]
		@possible_scopes = results.uniq
	end

	def << name, mappings
		scope_type = get_scope_type(mappings)
		raise "Invalid scope #{mappings.inspect}" unless scope_type
		@defined_scopes[name] = case scope_type
															when :reference then
																Reporter::Scope::ReferenceScope.new(self, name, mappings)
															when :date then
																Reporter::Scope::DateScope.new(self, name, mappings)
														end
		self
	end
	alias :add :<<

	def limit_scope scope, *args
		get(scope).limit = *args
	end

	def get scope
		raise "Scope does not exist" unless @defined_scopes.has_key? scope
		@defined_scopes[scope]
	end

	# internal

	def apply_on source, options
		removed_scopes = options[:remove_scopes] || []
		@defined_scopes.each do |name, scope|
			source = scope.apply_on(source) unless removed_scopes.include? name
		end
		source
	end

	def normalize_mapping mapping
		normalized = {}
		mapping.each do |key, value|
			key_s = key.to_s
			source = data_source.sources.find { |source| source.model_name.underscore == key_s.underscore }
			value_s = value.to_s
			normalized[source.model_name] = value_s
		end
		normalized.freeze
	end

	def valid_scope? mapping
		!(get_scope_type mapping == false)
	end

	def get_scope_type mapping
		mapping = normalize_mapping mapping
		#Rails.logger.info mapping.inspect
		valid = false
		possible.each do |fields|
			if (mapping.keys & fields.keys) == mapping.keys
				combination_valid = true
				mapping.each do |source, column|
					columns = fields[source].is_a?(Array) ? fields[source] : [fields[source]]
					#Rails.logger.info "#{columns.inspect} <=> #{column.inspect}"
					combination_valid = false unless columns.include? column
				end
				return fields[:type] if combination_valid
			end
		end
		false
	end

	# internal serialization

	def current_scope
		@scope_serialization
	end

	def apply_scope scope_serialization
		@scope_serialization = scope_serialization
	end

	def serialize_scope(scope_name, value)
		@scope_serialization[scope_name] = value
	end

	def unserialize_scope(scope_name)
		@scope_serialization[scope_name]
	end

	private

	attr_reader :data_source

	def possible_reference_scopes
		results = []
		global_references = nil
		data_source.sources.each do |source|
			global_references = global_references ? (global_references & source.references) : source.references
		end
		global_references.each do |reference|
			result_hash = {:type => :reference, :match => :exact}
			data_source.sources.each { |source| result_hash[source.model_name] = reference }
			results << result_hash
		end if global_references
		results
	end

	def possible_time_scopes
		results = []
		global_dates = nil
		specific_dates = {:type => :date, :match => :loose}
		data_source.sources.each do |source|
			global_dates = global_dates ? (global_dates & source.date_columns) : source.date_columns
			specific_dates[source.model_name] = source.date_columns
		end
		results << specific_dates
		global_dates.each do |reference|
			result_hash = {:type => :date, :match => :exact}
			data_source.sources.each { |source| result_hash[source.model_name] = reference }
			results << result_hash
		end if global_dates
		results
	end

end