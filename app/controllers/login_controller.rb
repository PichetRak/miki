class LoginController < ApplicationController
    def index

    end

    def sign_up
        @user = User.new()
    end

    def first_login
        @user = session["current_user"]
    end

    def update_password
        form_data = params[:change_password]
        generated_salt_password = BCrypt::Engine.generate_salt
        ecrypt_password = BCrypt::Engine.hash_secret(form_data[:password], generated_salt_password)
        # form_data[:password] = ecrypt_password
        # form_data[:salt_password] = generated_salt_password

        #### Check duplicate username
        if duplicate_username?(form_data[:username], params[:id]) || session["current_user"]["password"] == ecrypt_password
            flash[:error] = "Error: Username or password are already exists."
            return redirect_to login_change_password_path()
        end
        
        @user = User.update(params[:id], username: form_data[:username], salt_password: generated_salt_password, password: ecrypt_password, email: form_data[:email], phone_number: form_data[:phone_number], first_login: 1 )

        if @user.save!
            flash[:success] = "Your account is update successfully!, Welcome #{session["current_user"]["firstname"]} to virtual word!"
            redirect_to root_path()
        else
            flash[:error] = "Error: Cannot signup user. Please contact admin"
            redirect_to login_change_password_path()
        end
    end

    def create_account
        form_data = params[:user]

        generated_salt_password = BCrypt::Engine.generate_salt
        ecrypt_password = BCrypt::Engine.hash_secret(form_data[:password], generated_salt_password)
        form_data[:password] = ecrypt_password
        form_data[:salt_password] = generated_salt_password

        form_data[:role] = form_data[:personal_id] =~ /T/i ? 1 : 2
        form_data[:first_login] = 1

        #### Check duplicate username
        if duplicate_username? form_data[:username]
            flash[:error] = "Error: Username is already exists."
            return redirect_to login_sign_up_path(username: form_data[:username], firstname: form_data[:firstname], lastname: form_data[:lastname], classroom: form_data[:classroom], 
                    personal_id: form_data[:personal_id], email: form_data[:email], phone_number: form_data[:phone_number] )
        end
        
        @user = User.create(post_params)
        if @user.save!
            flash[:success] = "Your account is created successfully!"
            redirect_to login_path(:username => form_data[:username])
        else
            flash[:error] = "Error: Cannot signup user. Please contact admin"
            redirect_to login_sign_up_path(username: form_data[:username], firstname: form_data[:firstname], lastname: form_data[:lastname], classroom: form_data[:classroom], 
                                            personal_id: form_data[:personal_id], email: form_data[:email], phone_number: form_data[:phone_number] )
        end
    end

    def login
        username = params[:form_login][:username]
        password = params[:form_login][:password]

        @user = User.where(:username => username).limit(1).or(User.where(:personal_id => username).limit(1))
        if @user.present?
            @user.each do |u|
                ecrypt_password = BCrypt::Engine.hash_secret(password, u.salt_password)
                if u.password == ecrypt_password
                    session["current_user"] = u
                    if u.first_login == 0
                        flash[:success] = "Please update your password for login next time"
                        redirect_to login_change_password_path()
                    else
                        User.update(u.id, first_login: 1)
                        flash[:success] = "Login Successfully. Welcome #{u.firstname} to virtual word!"
                        redirect_to root_path()
                    end
                else
                    flash[:error] = "Your password is wrong. Please try again"
                    redirect_to login_path(:username => username)
                end
                break
            end
        else
            flash[:error] = "Your username or personal ID not found. Please signup and try again"
            redirect_to login_path()
        end
    end

    def logout
        session.delete "current_user"
        flash[:success] = "Log out successfully. BYE!"
        redirect_to login_path()
    end


    private
    def post_params
        params.require(:user).permit(:username, :password, :salt_password, :firstname, :lastname, :classroom, :personal_id, :email, :phone_number, :role, :first_login)
    end

    def duplicate_username? username, id = nil
        user = User.where(username: username)
        user = user.where.not(id: id) if id.present?
        return user.present?
    end
end
