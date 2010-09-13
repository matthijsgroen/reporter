class Reporter::Scope::ReferenceScope < Reporter::Scope::Base

	def initialize scoping, name, data_source, *args
		mappings = args.extract_options!
		mappings = create_mappings_for_object_type(data_source, args.first, mappings) if args.first
		super scoping, data_source, name, mappings
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

	def change object
		scoping.serialize_scope name, item
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
		if limiter
			limit_through_association source, reference, limiter
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

	def self.possible_scopes sources
		results = []
		# check reflections
		reflection_references = nil
		sources.each do |source|
			relations = source.relations_to_objects
			relation_pool = relations.keys + [source.active_record]
			reflection_references = reflection_references ? (reflection_references & relation_pool) : relation_pool
		end
		(reflection_references || []).each do |reflection_object|
			result_hash = { :type => :reference, :match => :loose, :object => reflection_object }
			sources.each do |source|
				fields = []
				fields << "id" if (source.active_record == reflection_object)
				fields += source.relations_to_objects[reflection_object] || []
				result_hash[source.model_name] = fields
			end
			results << result_hash
		end
		#Rails.logger.info reflection_references.inspect

		results
	end

	private

	def limit_through_association source, reference, limiter
		association = source.reflect_on_association(reference.to_sym)
		if association.macro == :belongs_to
			id_collection = get_ids_from limiter, reference
			#Rails.logger.info "Belongs to association #{reference} limited by #{limiter}: #{id_collection.inspect}"
			source.where("#{reference}_id".to_sym => id_collection)
		elsif association.macro == :has_one and association.options[:through]
			#Rails.logger.info "Has one through association #{reference} limited by #{limiter}"
			through_association = association.options[:through]
			limit_through_association source, through_association, limiter
		end
	end

	def get_ids_from item, reference
		return [] if item.nil?
		return item.collect { |sub_item| get_ids_from sub_item, reference }.flatten if item.is_a? Enumerable
		if item.class.ancestors.include? ActiveRecord::Base
			return [item.id] if item.class.name.underscore == reference
			return item.send("#{reference.to_s}_ids".to_sym) if item.respond_to? "#{reference.to_s}_ids"
			return [item.send("#{reference.to_s}_id".to_sym)] if item.respond_to? "#{reference.to_s}_id"
		end
		[]
	end

	def human_name_for item
		item.name
	end

	def create_mappings_for_object_type data_source, object, mappings
		possible = self.class.possible_scopes data_source.sources
		#Rails.logger.info possible.inspect
		possible.each do |reference_mapping|
			return create_mapping_from(reference_mapping, mappings, data_source.sources) if reference_mapping[:object] == object
		end
		raise "No valid data-source mapping could be made with #{object.name}"
	end

	def create_mapping_from reference_mapping, mapping_specifics, sources
		mapping = {}
		sources.each do |source|
			key = source.model_name.underscore.to_sym
			columns = reference_mapping[source.model_name]
			if columns.size == 1
				mapping[key] = columns.first
			else
				specific = mapping_specifics[key]
				if specific and columns.include? specific
					mapping[key] = mapping_specifics[key]
				else
					raise "No available reference for datasource #{source.model_name}"
				end
			end
		end
		#{ :funeral => "work_area", :cbs_statistic => "work_area" }
		Rails.logger.info mapping
		mapping
	end

end