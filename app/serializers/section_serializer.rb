# == Schema Information
#
# Table name: sections
#
#  section_num  :integer          not null, primary key
#  course_id    :integer
#  section_type :string
#  start_time   :string
#  end_time     :string
#  day_pattern  :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

class SectionSerializer < ActiveModel::Serializer
	# has_one :course 
	attributes :section_type, :start_time, :end_time, :day_pattern, :created_at
end 