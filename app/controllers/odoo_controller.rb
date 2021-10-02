require 'jwt'

class OdooController < ApplicationController

	skip_before_action :verify_authenticity_token

	def setpassword
      	decoded_token = JWT.decode(params[:token], ENV["BIGBLUEBUTTON_SECRET"], true, { algorithm: 'HS256' })
		if decoded_token[0]["email"].blank? || decoded_token[0]["password"].blank?
	        logger.error "Invalid Token"
        	render :json => false
      	end
      	user = User.find_by(email: decoded_token[0]["email"])
      	if user
	        user.password = decoded_token[0]["password"]
        	user.save
        	logger.info "Password successfully changed for the user #{decoded_token[0]["email"]}"
      		render :json => true
		else
	        logger.error "Account does not exist: #{decoded_token[0]["email"]}"
        	render :json => false
      	end
    end
end