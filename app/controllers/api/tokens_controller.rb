class Api::TokensController < ApplicationController
    skip_before_filter :verify_authenticity_token
    skip_before_filter :authenticate_user_from_token!
    skip_before_filter :authenticate_user!
    respond_to :json

    def create
        email = params[:email]
        password = params[:password]

        if request.format != :json
            render :status => 406, :json => { :error_message => "Request must be JSON" }
            return
        end

        if email.empty? or password.empty?
            render :status => 400,
                   :json => { :message => "Missing email or password" }
            return
        end

        @user = User.find_by_email(email.downcase)

        if @user.nil?
            logger.info("User #{email} failed signin, user cannot be found")
            render :status => 403, :json => { :message => "Invalid email or password" }
            return
        end

        if not @user.valid_password?(password)
            logger.info("User #{email} failed signin, password is invalid")
            render :status => 403, :json => { :message => "Invalid email or password" }
        else
            @user.ensure_authentication_token
            @user.save

            render :status => 200, :json => { :token => @user.authentication_token }
        end
    end

    def destroy
        @user=User.find_by_authentication_token(params[:id])

        if @user.nil?
            logger.info("Token not found.")
            render :status => 404, :json => { :message => "Invalid token" }
        else
            @user.reset_authentication_token!

            render :status => 200, :json => { :token => params[:id] }
        end
    end
end