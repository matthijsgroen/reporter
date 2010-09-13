class Reporter::Scope::Base

	def initialize scoping, name, mappings
		@scoping = scoping
		@name = name
		@mappings = scoping.normalize_mapping mappings
		@limit = nil
	end

	def limit= *args
		raise NotImplementedError
	end

	def value
		raise NotImplementedError
	end

	def apply_on source
		raise NotImplementedError
	end

	def iterate &block
		raise NotImplementedError
	end

	attr_reader :name, :mappings, :limit

	protected

	attr_reader :scoping

end