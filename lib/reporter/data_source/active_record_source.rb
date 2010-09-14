class Reporter::DataSource::ActiveRecordSource

	def initialize(data_source, active_record)
		@data_source = data_source
		@active_record = active_record
		@name = active_record.name.pluralize.underscore.to_sym
	end

	attr_reader :active_record, :name

	# scope detection methods
	def references
		load_columns if @references.nil?
		@references
	end

	def date_columns
		load_columns if @date_columns.nil?
		@date_columns
	end

	def relations_to_objects
		load_columns if @object_links.nil?
		@object_links
	end

	# display and inspection
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
		scope_options[:ignore_scopes] = [options.delete :ignore_scope] if options[:ignore_scope]
		scope_options[:ignore_scopes] = options.delete :ignore_scopes if options[:ignore_scopes]
		source_with_applied_scopes(scope_options).count *(args + [options])
	end

	def sum *args
		options = args.extract_options!.dup
		scope_options = {}
		scope_options[:ignore_scopes] = [options.delete :ignore_scope] if options[:ignore_scope]
		scope_options[:ignore_scopes] = options.delete :ignore_scopes if options[:ignore_scopes]
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
		@object_links = {}
		active_record.columns.collect do |column|
			if column.name =~ /^(.*)_id$/ and column.klass == Fixnum
				@references << $1
			elsif [Time, Date].include? column.klass
				@date_columns << column.name
			end
		end.compact

		active_record.reflect_on_all_associations.each do |reflection|
			@object_links[reflection.klass] ||= []
			@object_links[reflection.klass] << reflection.name.to_s
		end
	end

end