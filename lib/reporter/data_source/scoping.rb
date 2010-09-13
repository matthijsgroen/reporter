class Reporter::DataSource::Scoping

	SUPPORTED_SCOPES = {
		:date => Reporter::Scope::DateScope,
		:reference => Reporter::Scope::ReferenceScope
	}

	def initialize data_source
		@data_source = data_source
		@defined_scopes = {}
		@scope_serialization = {}
	end

	public

	def possible
		return @possible_scopes if @possible_scopes
		results = SUPPORTED_SCOPES.collect { |type_name, scope_type| scope_type.possible_scopes data_source.sources }.flatten
		#[{ :funeral => "work_area", :cbs_statistic => "work_area" }, { :funeral => "notification_date", :cbs_statistic => "month" }]
		@possible_scopes = results.uniq
	end

	def << scope_type, name, *args
		raise "Invalid scope #{scope_type}" unless SUPPORTED_SCOPES.keys.include? scope_type
		@defined_scopes[name] = SUPPORTED_SCOPES[scope_type].new(self, name, data_source, *args)
		#Rails.logger.info "Added scope #{name}: #{scope_type}"
		self
	end
	alias :add :<<

	def limit_scope scope, *args
		get(scope).limit = *args
	end

	def change changes
		changes.each do |scope, change|
			get(scope).change change
		end
		self
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
		if mapping.is_a? Hash
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
		elsif mapping.ancestors.include? ActiveRecord::Base
			return :reference
		end
		false
	end

	# internal serialization

	def current_scope
		scope_serialization
	end

	def apply_scope scope_serialization
		@scope_serialization = scope_serialization
	end

	def serialize_scope(scope_name, value)
		scope_serialization[scope_name] = value
	end

	def unserialize_scope(scope_name)
		scope_serialization[scope_name]
	end

	def method_missing(method_name, *args, &block)
		if method_name.to_s =~ /^add_(.*)_scope$/
			return send :add, $1.to_sym, *args, &block
		end
		super
	end

	def respond_to?(method_name)
		return true if method_name.to_s =~ /^add_(.*)_scope$/
		super
	end

	private

	attr_reader :data_source, :scope_serialization


end