require 'jwt'

class OdooController < ApplicationController

	skip_before_action :verify_authenticity_token
	before_action :getparams
	before_action :find_user, except:[:createuser, :testapi]

	def getparams
		decoded_token = JWT.decode(params[:token], ENV["BIGBLUEBUTTON_SECRET"], true, { algorithm: 'HS256' })
		@userparams = {
			name:decoded_token[0]["name"],
			email:decoded_token[0]["email"],
			image:decoded_token[0]["image"],
			password:decoded_token[0]["password"],
			uid:decoded_token[0]["uid"]
		}
	end

	def find_user
		@user = User.include_deleted.find_by(uid: @userparams[:uid])
		unless @user
	        logger.error "Account does not exist!"
        	raise "Account does not exist!"
		end
	end

	def testapi
		logger.info "#{@userparams}"
		render :json => @userparams
	end

	def createuser
		@user = User.include_deleted.find_by(email: @userparams[:email])
		if @user
			raise "User already exists!"
			logger.error "Invalid Data #{@userparams}"
		end
		@user = User.new({
			name: @userparams[:name],
			email: @userparams[:email],
			image: @userparams[:image],
			password: @userparams[:password],
			password_confirmation: @userparams[:password],
			provider: @userparams[:provider] || "greenlight",
			email_verified: true, accepted_terms: true
		})
		unless @user.valid?
        	raise "Invalid Data!"
			logger.error "Invalid Data #{@userparams}"
			render :json => false
		else
			@user.save
			@user.set_role(@userparams[:role] || "user")
			logger.info "User Created: #{@user.email}"
			render :json => @user.uid
		end
	end

	def updateuser
		if @userparams[:email]
			@user.email = @userparams[:email]
		end
		if @userparams[:name]
			@user.name = @userparams[:name]
		end
		if @userparams[:image]
			@user.image = @userparams[:image]
		end
		@user.save
		render :json => @user.uid
	end

	def updateuserpwd
	    @user.password = @userparams[:password]
        @user.save
		session.delete(:user_id)
		render :json => @user.uid
    end

	def inactiveuser
		@user.destroy(false)
		render :json => @user.uid
	end

	def activeuser
		@user.undelete!
    	@user.rooms.deleted.each(&:undelete!)
		render :json => @user.uid
	end

	def deleteuser
		@user.rooms.include_deleted.each do |room|
			delete_all_recordings(room.bbb_id)
			room.destroy(true)
		end
		@user.destroy(true)
		render :json => @user.uid
	end

end