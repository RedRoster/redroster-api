# == Schema Information 
# 
#  Table Name: schedule_elements
# 
#  PRIMARY KEY: (schedule_id, section_num)
# 
#  schedule_id 				:integer 						not null
#  section_num 				:integer						not null 
#  collision 					:boolean 						not null (set based on time collisions with other schedule elements)
#  created_at  				:datetime				 	 	not null
#  updated_at  				:datetime 				 	not null 

include ScheduleElementsHelper 

class Api::V1::ScheduleElementsController < Api::V1::ApplicationController

	before_action :grab_test_user 
	before_action :schedule_belongs_to_user 



	# EXTREMELY FAT CREATE METHOD (logic is somewhat complex for a reason.. this is how we're going to load the database w/info)
	# @ root of json, need :schedule_id 
	# w/in :section, we need :term, :subject, :course_num (1000...9999), :section_num (5-digit section num)
	def create 	
		# At this point, we have the schedule
		@section = Section.find_by_section_num(section_params[:section_num])
		# Tracks to the success of the action
		result = true 
		errors = []
		# Make the section (and the course) if their bare credentials don't exist in our db already 
		if @section.blank? 
			# All necessary to search for the required value 
			term = section_params[:term]
			subject = section_params[:subject]
			course_num = section_params[:course_num]
			section_num = section_params[:section_num]
			# Create this value 
			url_string = "https://classes.cornell.edu/api/2.0/search/classes.json?roster=#{term}&subject=#{subject}&q=#{course_num}"
			p url_string
			uri = URI(url_string)
			res_json = JSON.parse(Net::HTTP.get(uri))
			if res_json["status"] != "error"

				course_info = res_json["data"]["classes"][0]
				@course = Course.find_by_course_id(course_info["crseId"])
				# If this course doesn't exist, create it as necessary 
				if @course.blank? 
					@course = Course.create(course_id: course_info["crseId"], term: term, subject: subject, number: course_num)
				end 

				sections = course_info["enrollGroups"][0]["classSections"]
				# If the section does not exist w/in the specified Course 
				section_dets = section_details(sections, section_num)
				if section_dets.blank? 
					render json: { success: false, data: { error: "This section does not exist with within this term and course."}} and return false 
				end 

				@section = Section.create(section_num: section_num, 
																	course_id: @course.course_id, 
																	section_type: section_type[0], 
																	start_time: section_type[1],
																	end_time: section_type[2],
																	day_pattern: section_type[3])	

			else 
				result = false 
			end 
		end 
		# At this point, we have the @section and the @schedule we care about 
		@schedule_element = ScheduleElement.create(schedule_id: @schedule.id, section_num: @section.section_num)
		if @schedule_element.errors.any? 
			result = false 
			@schedule_element.errors.full_messages.each do |fm| 
				errors.push(fm)
			end 
		end 
		render json: { success: result, data: { errors: errors } }
	end 





	# Delete a schedule element from a specific schedule 
	def destroy
		# We have the schedule 
		@schedule_element = ScheduleElement.where(schedule_id: @schedule.id).find_by_section_num(section_params[:section_num])
		if !@schedule_element.blank?
			@schedule_element.delete
		end 
		render json: { success: !@schedule_element.blank? }
	end 






	private 

		# Parameters necessary to creation this section as necessary 
		def section_params
			params.require(:section).permit(:term, :schedule_id, :subject, :course_num, :section_num)
		end 



end
