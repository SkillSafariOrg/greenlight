class OdooController < ApplicationController

    skip_before_action :verify_authenticity_token
  
    def setpassword
      if params[:email].blank? || params[:password].blank?
        logger.error "Missing Arguments"
        render :json => false
      end
      user = User.find_by(email: params[:email])
      if user
        user.password = params[:password]
        user.save
        logger.info "Password successfully changed for the user #{params[:email]}"
      else
        logger.error "Account does not exist: #{params[:email]}"
        render :json => false
      end
      logger.info "******** ===> #{params}"
      render :json => true
    end
  
  end 