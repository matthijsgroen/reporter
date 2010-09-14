Reporter
========
Reporter is a small Ruby / Rails 3.0 library for building reports. It is in heavy development right now, so documentation is sparse and code could change drastically from day to day.

Goal
====
The goal is to create an easy to use reporting tool that not the programmer, but the client can build their own reports using data from the system.

1. The client gets a rich AJAX web-interface to build their report data together, apply markup and store the report as a template
2. The client gets to see up to date reporting information when they open the template, even with filter and navigation options

Design
======
This project will consist of several different parts. The first part is to collect and query the data.
The second part is to display that data in nice views or exports.
The third part is a rich web interface so that customers can build their own reports.

The code
========

Dependencies
------------
As of now the code is dependent on ActiveRecord from Rails 3.

Installation and Use
--------------------
Since it is in the early development stages, there are no Gem builds available. The tool is not yet for production use, and should only be used in experimental applications. The way I develop it now is pull the project in a folder on your workstation, create a new Rails 3 project and make a symlink folder from the lib/reporter folder to the app/models/reporter folder. This is for code reloading between requests. The goal is to have a Gem in a later stadium.

Examples
========
This code is done in the controller

	# 1. Build the dataset
	market_share_report = Reporter::DataSet.new do |r|
		r.data_source = Reporter::DataSource.new do |data_set|
			
			# 1a. Add the sources to extract data from
			data_set << Sale << MarketshareStatistic
			#Rails.logger.info data_set.scopes.possible.inspect # You can get a list of possible links between the given models
			
			# 1b. Link the sources together on common properties
			data_set.scopes.add_date_scope :time, :sale => "date", :marketshare_statistic => "date"
			data_set.scopes.add_reference_scope :area, Area
		end

		# 1c. Add the fields / values / calculations to extract from the datasources
		r.data_structure do |row|
			row.add_field :period, :time
			row.add_count_field :sales, :sales
			row.add_sum_field :sales_workarea, :marketshare_statistics, "amount_sold"
			row.add_formula_field :area_marketshare, "sales / sales_workarea"
			row.add_sum_field :sales_national, :marketshare_statistics, "amount_sold", :ignore_scope => :area, :conditions => { :area_id => nil }
			row.add_formula_field :national_marketshare, "sales / sales_national"
		end
	end

	# 2. set master scopes
	market_share_report.data_source.scopes.limit_scope :time, 2010 # same as Date.civil(2010).beginning_of_year .. Date.civil(2010).end_of_year
	market_share_report.data_source.scopes.limit_scope :area, Company.first
	
	@market_share = market_share # expose report for view

This code is for the view (HAML example)

	%h1 
		Marketshare report for
		= @market_share_report.scope_name :area
		= @market_share_report.scope_name :time
	%table.report
		%thead
			%th Month
			%th Sales
			%th Sales in area
			%th Marketshare in area
			%th National sales
			%th National marktetshare
		%tbody
			- @market_share_report.iterate_time :time, :month, :quarter, :year do
				- row = @market_share_report.get_row
				%tr
					%td= row[:period] # The query will fire at this point. so caching makes huge profit!
					%td= row[:funerals]
					%td= row[:deaths_workarea]
					%td= row[:workarea_marketshare].as_percentage
					%td= row[:deaths_national]
					%td= row[:national_marketshare].as_percentage

In detail: Building the dataset
===============================

	# 1. Build the dataset
	market_share_report = Reporter::DataSet.new do |r|
		r.data_source = Reporter::DataSource.new do |data_set|
			
			# 1a. Add the sources to extract data from
			data_set << Sale << MarketshareStatistic
			#Rails.logger.info data_set.scopes.possible.inspect # You can get a list of possible links between the given models

Data sources and scopes
-----------------------
ActiveRecord models are added as datasources. The system will try to find common properties to scale the models against. This happens using
class methods on Scope classes (DateScope and ReferenceScope). 

DateScope looks for date / time fields to lay the models next to each other.
If they find the same columnname on all models (created_at, updated_on) they will indicate an exact match. Otherwise it suggests a loose match. The strictness of the match is not relevant for building and linking the dataset, but an indicator for building a UI. 

ReferenceScope looks for the same type of Object association on all models. if all models have an _belongs_to :area_ method, the ReferenceScope will suggest a link through "area". You can even have a has_one relationship through a belongs to.
So: 
	has_one :area, :through => :sale_area
is supported.
			
			# 1b. Link the sources together on common properties
			data_set.scopes.add_date_scope :time, :sale => "date", :marketshare_statistic => "date"
			data_set.scopes.add_reference_scope :area, Area
		end

After the suggestions (which in code you won't use actively) you have to set the scopes on the properties, and decide wich fields to link together.
In the reference example, all models only have one association to the Area object, so no specific columname is needed. (it will figure that out itself)

We have one big pool of data, wich is filterable through scopes (time and area in this case)
Now we have to tell how to extract the data from the set. Calculations are defined here.

		# 1c. Add the fields / values / calculations to extract from the datasources
		r.data_structure do |row|
			row.add_field :period, :time
			row.add_count_field :sales, :sales
			row.add_sum_field :sales_workarea, :marketshare_statistics, "amount_sold"
			row.add_formula_field :area_marketshare, "sales / sales_workarea"
			row.add_sum_field :sales_national, :marketshare_statistics, "amount_sold", :ignore_scope => :area, :conditions => { :area_id => nil }
			row.add_formula_field :national_marketshare, "sales / sales_national"
		end
	end

Field types
-----------
As you can see there are several different field types to add.

*Field* If passed a regular value, this value is set for the field with the given name.
If passed a Symbol, the name of the scope of the symbol will be used as value
you can even pass a block an create a custom field with own querie mechanisms or function calls

*CountField* counts the records of a given datasource (second parameter) the datasource is here used in plural. (don't know if it will stay this way). An optional hash with conditions can be provided.

*SumField* similar to the CountField, this fieldtype will sum up all results from a column of a given datasource (datasource is param 3, column is param 4)
in the line :sales_national you can see the use of :ignore_scope and an additional conditions hash.

*:ignore_scope* before retrieval of field data the correct scopes will be built for query execution. If certain scopes must be ignored for certain fields, you can use
:ignore_scope => :scope_name or :ignore_scopes => [:scope, :scope]

*FormulaField* the formula field is for simple calculations. variable names used will be retrieved from their active row.


Limits
------
At last default limits are set for the scopes. This can be overridden (temporarily) by iterators used in views.

	# 2. set master scopes
	market_share_report.data_source.scopes.limit_scope :time, 2010 # same as Date.civil(2010).beginning_of_year .. Date.civil(2010).end_of_year
	market_share_report.data_source.scopes.limit_scope :area, Company.first
	
	@market_share = market_share # expose report for view


In detail: Building the view
============================


	%h1 
		Marketshare report for
		= @market_share_report.scope_name :area
		= @market_share_report.scope_name :time
	%table.report
		%thead
			%th Month
			%th Sales
			%th Sales in area
			%th Marketshare in area
			%th National sales
			%th National marktetshare
		%tbody
			- @market_share_report.iterate_time :time, :month, :quarter, :year do
				- row = @market_share_report.get_row
				%tr
					%td= row[:period] # The query will fire at this point. so caching makes huge profit!
					%td= row[:funerals]
					%td= row[:deaths_workarea]
					%td= row[:workarea_marketshare].as_percentage
					%td= row[:deaths_national]
					%td= row[:national_marketshare].as_percentage

