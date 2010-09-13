class Reporter::DataSource::ActiveRecordSource

	def initialize(data_source, active_record)
		@data_source = data_source
		@active_record = active_record
		@name = active_record.name.pluralize.underscore.to_sym
	end

	attr_reader :active_record, :name

	def references
		load_columns if @references.nil?
		@references
	end

	def date_columns
		load_columns if @date_columns.nil?
		@date_columns
	end

	def inspect
		@active_record.inspect
	end

	def model_name
		@active_record.name
	end

	# retrieve data from source
	def count *args
		options = args.extract_options!.dup
		scope_options = {}
		scope_options[:remove_scopes] = [options.delete :remove_scope] if options[:remove_scope]
		scope_options[:remove_scopes] = options.delete :remove_scopes if options[:remove_scopes]
		source_with_applied_scopes(scope_options).count *(args + [options])
	end

	def sum *args
		options = args.extract_options!.dup
		scope_options = {}
		scope_options[:remove_scopes] = [options.delete :remove_scope] if options[:remove_scope]
		scope_options[:remove_scopes] = options.delete :remove_scopes if options[:remove_scopes]
		source_with_applied_scopes(scope_options).sum *(args + [options])
	end

	def source_with_applied_scopes(options)
		#Rails.logger.info options.inspect
		@data_source.scopes.apply_on(@active_record, options)
	end

	private

	def load_columns
		@references = []
		@date_columns = []
		active_record.columns.collect do |column|
			if column.name =~ /^(.*)_id$/ and column.klass == Fixnum
				@references << $1
			elsif [Time, Date].include? column.klass
				@date_columns << column.name
			end
		end.compact

	end

end