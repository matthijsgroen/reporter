module Reporter::TimeIterator

	public

	VALID_TIME_STEP_SIZES = :total, :year, :quarter, :month, :week, :day

	def iterate_time axis, *steps, &block
		options = steps.extract_options!
		scope = data_source.scopes.get axis
		raise "Scope is not of Date type" unless scope.is_a? Reporter::Scope::DateScope
		steps.each do |step|
			raise "invalid stepsize: #{step}. must be one of #{VALID_TIME_STEP_SIZES.inspect}" unless VALID_TIME_STEP_SIZES.include? step
		end
		date_tree = build_date_tree steps
		iterate_date_tree scope, date_tree, scope.limit, &block
		scope.change nil
	end

	private

	DATE_PART_VALUES = {
					:total => 6,
					:year => 5,
					:quarter => 4,
					:month => 3,
					:week => 2,
					:day => 1
	}

	def build_date_tree date_parts
		date_parts = date_parts.dup
		return nil if date_parts.empty?
		# [6, 4, 3, 5]
		# 2010 - 2011, q1, 1,2,3, q2, 4,5,6, q3, 7,8,9, q4, 10,11,12, 2010, q1, 1,2,3, q2, 4,5,6, q3, 7,8,9, q4, 10,11,12, 2011
		date_coded = date_parts.collect { |part| DATE_PART_VALUES[part] }
		if date_coded.first == date_coded.max
			parent = date_parts.shift
			{:children_first => false, :name => parent, :children => build_date_tree(date_parts)}
		elsif date_coded.last == date_coded.max
			parent = date_parts.pop
			{:children_first => true, :name => parent, :children => build_date_tree(date_parts)}
		else
			raise "invalid sequence: #{date_parts.inspect}"
		end
	end

	def iterate_date_tree scope, tree, time_frame, &block
		iterate_time_periods time_frame, tree[:name] do |new_time_frame|
			iterate_date_tree scope, tree[:children], time_frame, &block if tree[:children_first] and tree[:children]
			scope.change new_time_frame
			yield
			iterate_date_tree scope, tree[:children], time_frame, &block if !tree[:children_first] and tree[:children]
		end
	end

	def iterate_time_periods period, block_type, &block
		if block_type == :total
			yield period
			return
		end
		advancement = case block_type
			when :year : { :years => 1 }
			when :quarter : { :months => 3 }
			when :month : { :months => 1 }
			when :week : { :weeks => 1 }
			when :day : { :days => 1 }
			else raise "Unsupported type: #{block_type}"
		end
		iterate_period = period.begin.send("beginning_of_#{block_type}".to_sym) .. period.begin.send("end_of_#{block_type}".to_sym)

		while iterate_period.begin < period.end
			yield iterate_period
			iterate_period = iterate_period.begin.advance(advancement).send("beginning_of_#{block_type}".to_sym) ..
							iterate_period.end.advance(advancement).send("end_of_#{block_type}".to_sym)
		end
	end

end