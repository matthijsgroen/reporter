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
		active_record.inspect
	end

	def model_name
		active_record.name
	end

	# retrieve data from source
	def calculate calculation, *args, &block
		options = args.extract_options!.dup
		scope_options = extract_scope_options_from options
		source = source_with_applied_scopes(scope_options)
		source = block.call(source, data_source.scopes) if block_given?
		source.send *([calculation] + args + [options])
	end

	def calculate_for_period calculation, period, filter, scope, *args, &block
		options = args.extract_options!.dup
		# remove the time scope from the default scopes
		scope_options = extract_scope_options_from options
		scope_options[:ignore_scopes] << scope.name.to_sym
		scope_options[:ignore_scopes].uniq!
		source = source_with_applied_scopes(scope_options)
		source = block.call(source, data_source.scopes) if block_given?
		# add time scope seperately with full period
		source = scope.apply_on source, period

		grouping = filter.collect { |f| scope.group_on source, f }
		source = source.group grouping.join(", ")
		select = []
		select << calculation_function(calculation, args)
		filter.each_with_index { |f, index| select << "#{grouping[index]} as #{f.to_s}" }
    source = source.select select
		result = source.collect do |r|
			result = r.result.to_f
			result = result.to_i if result.floor == result
			res = { :value => result }
			filter.each { |f| res[f] = r[f.to_s].to_i }
			res
		end
		#Rails.logger.info source.to_sql
		result
	end

	def source_with_applied_scopes(options)
		#Rails.logger.info options.inspect
		data_source.scopes.apply_on(active_record, options)
	end

	private

	attr_reader :data_source

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

	def extract_scope_options_from options
		scope_options = {}
		scope_options[:ignore_scopes] = options.delete(:ignore_scopes) || []
		scope_options[:ignore_scopes] += [options.delete :ignore_scope] if options[:ignore_scope]
		scope_options
	end

	def calculation_function(calculation, args)
		case calculation
			when :sum :
				"SUM(#{args.first}) AS result"
			when :count :
				"COUNT(*) AS result"
			when :average :
				"AVG(#{args.first}) AS result"
		end
	end

end