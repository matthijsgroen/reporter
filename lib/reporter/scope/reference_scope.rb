class Reporter::Scope::ReferenceScope < Reporter::Scope::Base

	def initialize scoping, name, mappings
		super scoping, name, mappings
		@limiter = nil
		@id_collection = nil
	end

	def limit= object_or_array
		@limiter = object_or_array
	end

	def group_object
		scoping.unserialize_scope(name)
	end

	def value
		group_object || @limiter
	end

	def human_name
		limiter = group_object || @limiter
		return limiter.collect { |item| human_name_for item }.to_sentence if limiter.is_a? Enumerable
		human_name_for limiter
	end

	def apply_on source
		raise "No mapped column for source #{source}" unless mappings.has_key? source.name
		reference = mappings[source.name]

		limiter = group_object || @limiter
		#Rails.logger.info mappings.inspect
		if limiter
			id_collection = get_ids_from limiter, reference
			#Rails.logger.info id_collection.inspect
			source.where("#{reference}_id".to_sym => id_collection)
		else
			source
		end
	end

	def iterate items, &block
		items ||= @limiter
		if items.is_a? Enumerable
			items.each do |item|
				scoping.serialize_scope name, item
				yield
			end
			scoping.serialize_scope name, nil
		else
			scoping.serialize_scope name, items
			yield
			scoping.serialize_scope name, nil
		end
	end


	private

	def get_ids_from item, reference
		return [] if item.nil?
		return item.collect { |sub_item| get_ids_from sub_item, reference }.flatten if item.is_a? Enumerable
		if item.class.ancestors.include? ActiveRecord::Base
			return [item.id] if item.class.name.underscore == reference
			return get_ids_from item.send(reference.pluralize.to_sym), reference if item.respond_to? reference.pluralize
		end
		[]
	end

	def human_name_for item
		item.name
	end

end