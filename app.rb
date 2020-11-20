require_relative './config/environment.rb'

user = nil

while true
    User.prompt.keypress("Press space or enter to continue", keys: [:space, :return])

    if user == nil
        user = User.start
    else
       user = user.main_menu
    end
end