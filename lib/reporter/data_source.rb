
class Reporter::DataSource

	def initialize *args, &block
		@sources = []
		@scopes = Reporter::DataSource::Scoping.new self
		yield self if block_given?
	end

	def << source
		@sources << wrap_source(source)
		self
	end
	alias :add :<<

	def get name
		sources.detect { |source| source.name == name } or raise "Source #{name} not found"
	end

	attr_reader :scopes, :sources

	private

	def wrap_source source
		if source.ancestors.include? ActiveRecord::Base
			Reporter::DataSource::ActiveRecordSource.new(self, source)
		end
	end

end
