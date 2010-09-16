require "reporter/support/time_range"

# DataSet is where all information about the data for the report comes together.
#
class Reporter::DataSet

	def initialize *args
		@row_structure = nil
		@axis_values = {}

		@row_cache = {}
		yield self if block_given?
	end

	def data_source= value
		#TODO Maybe add checks, maybe make the datasource an internal part of the reporting dataset
		@data_source = value
	end

	attr_reader :data_source

	# creation of the definition of the available fields/values to retrieve from the various datasources
	def data_structure *args, &block
		@data_structure ||= Reporter::DataStructure.new self, *args
		yield @data_structure if block_given?
		@data_structure
	end

	def get_row options = {}
		# The datastructure of a resultrow it is a container for caching result values so that
		# formula's can retrieve values to perform calculations. Queries are executed as late as
		# possible. This way template caching can eliminate performing database queries altogether.
		current_scope = data_source.scopes.change(options).current_scope
		@row_cache[current_scope.hash] ||= Reporter::ResultRow.new(self, current_scope)
	end

	# iterate the chosen scope over a list of selected items. If no items are provided the defined
	# maximum and minimum limit is used. (scope.set_limit)
	# use iterate_time to iterate over time periods.
	def iterate scope, items = nil, &block
		raise "No data-source set" unless data_source
		data_source.scopes.get(scope).iterate items, self, &block
	end

	# returns the name of the current active scope. This can be used to decorate report data with the proper context
	def scope_name scope
		raise "No data-source set" unless data_source
		data_source.scopes.get(scope).human_name
	end

	include Reporter::TimeIterator

end