module Reporter::Support::TimeRange

	def time_range?
		valid_types = [Date, DateTime, Time, ActiveSupport::TimeWithZone]
		return false unless valid_types.include?(self.begin.class)
		return false unless valid_types.include?(self.end.class)
		true
	end

	def humanize
		return inspect unless time_range?
		b = test_begin_ends(self.begin)
		e = test_begin_ends(self.end)

		if self.begin.year == self.end.year
			if b[:by] and e[:ey]
				return self.begin.strftime("%Y")
			elsif b[:bq] and e[:eq]
				bq = get_quarter(self.begin)
				eq = get_quarter(self.end)
				if bq == eq
					return I18n.t("time_range.quarter", :year => self.begin.year, :quarter => bq, :default => "q%{quarter} %{year}")
				else
					return I18n.t("time_range.multi_quarter", :year => self.begin.year,
												:begin_quarter => bq, :end_quarter => bq, :default => "q%{begin_quarter} .. q%{end_quarter} %{year}")
				end
			elsif b[:bm] and e[:em]
				if self.begin.month == self.end.month
					return self.begin.strftime("%b '%y")
				else
					return "#{self.begin.strftime("%b")} .. #{self.end.strftime("%b '%y")}"
				end
			end
		else # multi year
			if b[:by] and e[:ey]
				return "#{self.begin.strftime("'%y")} .. #{self.end.strftime("'%y")}"
			else
				return inspect
			end
		end
	end

	private

	def get_quarter(date)
		qs = [3, 6, 9, 12]
		q = qs.detect { |q| date.month <= q }
		(qs.index q) + 1
	end

	def test_begin_ends(date)
		r = {}
		["year", "quarter", "month", "week"].each do |element|
			r["b#{element.first}".to_sym] = (date.send("at_beginning_of_#{element}".to_sym) == date)
			r["e#{element.first}".to_sym] = (date.send("at_end_of_#{element}".to_sym) == date)
		end
		r
	end

end

Range.send(:include, Reporter::Support::TimeRange)