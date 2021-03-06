class JobsController < ApplicationController
	before_action :set_job, only: [:edit, :show, :update, :destroy, :changeAppStatus, :userApply, :userUnapply]
	autocomplete :skill, :name, :full=>true, :class_name => 'ActsAsTaggableOn::Tag'

	def index
		@jobs = Job.text_search(params[:search])
	end

	def new
		@job = Job.new
	end


	def userApply
		result=@job.addUser(current_user[:id])
		redirect_to current_user
	end

	def userUnapply
		result=@job.removeUser(current_user[:id])
		redirect_to current_user
	end



	def show
		@org=current_user.organizations.first
		users=@job.users
		@considering=[]
		@accepted=[]
		@rejected=[]
		users.each do |user|
			ja=Jobapp.find_by_user_id_and_job_id(user[:id], @job[:id])
			if ja[:status]==0 || (ja[:status]).nil?
				@considering << user
			elsif ja[:status]==1
				@accepted << user
			elsif ja[:status]==2
				@rejected << user
			end
		end

	end

	def create
		@job = Job.new(job_params)
		@job.skill_list = job_params[:skill_list]
		respond_to do |format|
			if @job.save
				current_user.organizations.first.jobs << @job
				format.html { redirect_to @job, notice: 'Job was succesfully created' }
				format.json { render action: 'show', status: :created, location:@job }
			else
				format.html { render action: 'new' }
				format.json { render json: @job.errors, status: :unprocessable_entity }
			end
		end
	end

	def edit
	end

	def update
		respond_to do |format|
			if @job.update(job_params)
				@job.skill_list = job_params[:skill_list]
				format.html { redirect_to @job, notice:'Successful update' }
				format.json { head :no_content}
			else
				format.html { render action: 'edit' }
				format.html { render json: @job.errors, status: :unprocessable_entity}
			end
		end
	end

	def changeAppStatus
		rdata=request.POST
		uid=rdata[:uid]
		if current_user.organizations.first != @job.organization
			redirect_to '/'
		end
		status=rdata[:status]
		@job.changeAppStatus(uid, status)
		redirect_to @job
	end

	def destroy
		org = @job.organization
		@job.destroy
    respond_to do |format|
	    format.html { redirect_to org }
	    format.json { head :no_content }
    end
	end

	private 
		def set_job
			@job = Job.find(params[:id])
		end

		def job_params
			params.require(:job).permit(:title, :description, :skill_list)
		end

end
