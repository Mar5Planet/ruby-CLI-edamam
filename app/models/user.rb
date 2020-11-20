class User < ActiveRecord::Base
    has_many :favorite_recipes
    has_many :recipes, through: :favorite_recipes

    @@prompt = TTY::Prompt.new;
    
    def self.prompt 
        @@prompt
    end
    # ----------------------LOGIN METHODS----------------------------------------------------------
    def self.start
        Logo.fitbud_logo
        input = User.prompt.select('Welcome to Fitbbud, select an option', ['Login'.colorize(:blue), 'Create Account'.colorize(:blue), 'Exit'.colorize(:red)])
        if input == 'Login'.colorize(:blue)
             User.login
        elsif input == 'Create Account'.colorize(:blue)
             User.create_account
        elsif input == 'Exit'.colorize(:red)
            abort('PROGRAM TERMINATED'.colorize(:red))
        end
    end

    def self.check_account
        puts "Enter Username".colorize(:green)
        user_name = gets.chomp
        puts "Enter Password".colorize(:green)
        password = User.prompt.mask("Please enter password?")

        foundUser = self.all.find do |user|
            user.username == user_name and user.password == password
        end
    end

    def self.login
        user = User.check_account
        if user
            puts "Welcome #{user.first_name}"
            user
        else
            puts "NOT A VALID ACCOUNT---RETURNING TO MAIN MENU"
        end
    end

    def self.create_account
        puts "Please enter desired username"
        user_name = gets.chomp
        query = User.all.find{|u| u.username == user_name}
        if query 
            puts "Username taken"
            return
        end
        password = User.prompt.mask("Please enter password?")
        
        puts "Enter your first name"
        firstname = gets.chomp
        puts "Enter your last name"
        lastname = gets.chomp

        gender = User.prompt.select("Enter your gender", ['M', 'F'])
        age = User.prompt.ask("How old are you, #{firstname}?") do |age| 
            age.in("0-120")
            age.messages[:range?] = "%{value} is not a valid age. Please enter an age between 0 - 120 years old"
        end
        
        user = User.create(first_name: firstname, last_name: lastname, username: user_name, password: password, gender: gender, age: age)
        user.set_diet
        user.calculate_BMR
        user
    end

    # ----------------------MAIN MENU----------------------------------------------------------
    def main_menu
        Logo.fitbud_logo

        menu_options = [
            'Profile Overview',
            'Dietary recipe search',
            'BMR recipe search',
            'Search by recipe name',
            'Search by keyword',
            'KeyWord + Calorie limit search',
            'View personal favorites',
            'View top recipes',
            'Reset user profile',
            'Reset Password',
            'Delete Profile',
            'Logout'
        ]
        input = User.prompt.select("Welcome to FitBUD #{self.first_name}, this is the Main Menu:", menu_options)

        if input == 'Dietary recipe search'
            self.recipe_viewer(self.constant_recipes)
            self
        elsif input == 'Search by keyword'
            puts "Enter a search keyword:"
            self.key_word_search
            self
        elsif input == 'View personal favorites'
            self.view_favorites
            self
        elsif input == "Logout"
            puts "#{self.username} Logged out"
            nil
        elsif input == 'Reset user profile'
            self.set_diet 
            self.calculate_BMR
            self
        elsif input == 'BMR recipe search'
            self.bmr_search
            self
        elsif input == 'View top recipes'
            top_recipes_array = Recipe.top_users.map do |key, value| 
                key 
            end
            self.recipe_viewer_for_fav(top_recipes_array)
            self
        elsif input == 'Profile Overview'
            self.view_profile
            self
        elsif input == 'Delete Profile'
            was_deleted = self.secret_nuke
            
        elsif input == 'Reset Password'
            self.reset_password
            self
        elsif input == 'KeyWord + Calorie limit search'
            self.keyword_search_with_calorie
            self
        elsif input == 'Search by recipe name'
            self.recipe_name_search
            self
        end

    end
    
    # ----------------------MENU OPTIONS----------------------------------------------------------


    # ----------------------QUERY METHODS----------------------------------------------------------
    
    # ----------------------QUERY BY USER PREF----------------------------------------------------------
    def constant_recipes
        user_diet_pref = self.dietary_preferences.split(' ')
        if self.dietary_preferences == ""
            results = Recipe.all.select {|recipe| recipe.diet_labels.include?(self.diet) }
        else 
            results = Recipe.all.select do |recipe|
                user_diet_pref.all? {|pref| recipe.health_labels.include?(pref)}
            end.select {|recipe| recipe.diet_labels.include?(self.diet) }
        end
        results
    end

    def bmr_search
        puts "According to our calculations your daily caloric intake is #{self.caloric_intake} for your goal of #{self.goal}"
        meal_calories = (self.caloric_intake)/3
        self.recipe_viewer(self.constant_recipes.filter{|r| r.calories <= meal_calories and r.calories >= (meal_calories-200)})
    end

    # ----------------------QUERY(WHOLE DB) BY USER INPUT----------------------------------------------------------
    def recipe_name_search
        key_word = User.prompt.ask("Please piece of recipe name")
        key_word == nil ? (key_word = 'bdncjkascndxasklxnasmndxb') : (key_word)
        recipe_query = Recipe.all.filter{|recipe| recipe.name.include?(key_word.capitalize())}

        if recipe_query != []
            recipe_viewer(recipe_query)
        else
            puts 'Invalid Search!'.colorize(:red);
        end
    end

    def key_word_search
        key_word = User.prompt.ask("Please enter keyword")
        key_word == nil ? (key_word = 'bdncjkascndxasklxnasmndxb') : (key_word)
        recipe_query = Recipe.all.filter{|recipe| recipe.name.include?(key_word.capitalize()) or recipe.ingredients.include? key_word}

        if recipe_query != []
            recipe_viewer(recipe_query)
        else
            puts 'Invalid Search!'.colorize(:red);
        end
    end

    def keyword_search_with_calorie
        key_word = User.prompt.ask("Please enter keyword")
        key_word == nil ? (key_word = 'bdncjkascndxasklxnasmndxb') : (key_word)
        max_calories = User.prompt.ask('Please enter max calorie amount').to_i
        max_calories == nil ? (max_calories = 0) : (max_calories)

        recipe_query = Recipe.all.filter{|recipe| recipe.name.include?(key_word.capitalize()) or recipe.ingredients.include? key_word}.select {|r| r.calories <= max_calories}

        if recipe_query != []
            recipe_viewer(recipe_query)
        else
            puts 'Invalid Search!'.colorize(:red);
        end
    end




    # ----------------------ACCOUNT METHODS----------------------------------------------------------

    def view_profile
        puts "USERNAME: ".colorize(:blue).bold  + "#{self.username.colorize(:magenta)}"
        puts "FULL NAME: ".colorize(:blue).bold + "#{self.first_name} #{self.last_name}".colorize(:magenta)
        self.gender == 'M' ? (puts 'GENDER: '.colorize(:blue).bold + 'MALE'.colorize(:magenta)) : (puts 'GENDER: '.colorize(:blue).bold + 'FEMALE'.colorize(:magenta))
        puts "AGE: ".colorize(:blue).bold + "#{self.age} years old".colorize(:magenta)
        puts "WEIGHT: ".colorize(:blue).bold  + "#{self.weight}kg".colorize(:magenta)
        puts "HEIGHT: ".colorize(:blue).bold + "#{self.height}cm".colorize(:magenta)
        puts "DIETARY CHOICES: ".colorize(:blue).bold + "#{self.diet}, #{self.dietary_preferences}".colorize(:magenta)
        puts "FITNESS GOAL: ".colorize(:blue).bold + "#{self.goal}".colorize(:magenta)
        puts "BMR: ".colorize(:blue).bold + "#{self.caloric_intake} burned per day".colorize(:magenta)
    end
    
    def calculate_BMR 

        self.activity_level = User.prompt.select("What is your activity level?", ['Low/No Activity', 'Moderate Activity', 'Very Active'])

        self.height = BasicCalc.inches_to_cm(User.prompt.ask("#{self.first_name}, what is your height (inches)?") do |height| 
            height.in("21-120") 
            height.messages[:range?] = "%{value}inches is not in the range of 21 inches - 120 inches"
        end)
        
        self.weight = BasicCalc.pounds_to_kg(User.prompt.ask("#{self.first_name}, what is your weight (lb)?") do |weight|
            weight.in("0-881") 
            weight.messages[:range?] = "%{value}lb is not a valid weight. Please enter a weight between of 0(lb) - 881(lb)"
        end)
    
        self.goal = User.prompt.select('What is your fitness goal?', ["Cut/lose Weight", 'Maintain Weight', 'Bulk/Gain Weight'])

        if self.activity_level == 'Very Active'
            activity_factor = 500
        elsif self.activity_level == 'Moderate Activity'
            activity_factor = 300
        else
            activity_factor = 0
        end

        if self.goal == 'Bulk/Gain Weight'
            goal_factor = 400
        elsif self.goal == 'Maintain Weight' 
            goal_factor = 0
        else
            goal_factor = - 250
        end 
    
        if self.gender == 'M'
            self.caloric_intake = (13.397 * (self.weight)) + (4.799 * (self.height)) - (5.677*(self.age)) + 188.362 + activity_factor + goal_factor
        elsif self.gender == 'F'
            self.caloric_intake = (9.247 * (self.weight)) + (3.098 * (self.height)) - (4.330*(self.age)) + 647.593 + activity_factor + goal_factor
        end
        self.save
        puts "Your daily calorie goal is #{self.caloric_intake} calories".colorize(:blue).bold
    end 

    def set_diet
        diet_choices = %w(Balanced High-Protein Low-Fat Low-Carb)
        self.diet = User.prompt.select("Select diet type?", diet_choices)

        dietary_preferences = %w(Vegan Vegetarian Sugar-Conscious Peanut-Free Tree-Nut-Free Alcohol-Free)
        self.dietary_preferences = User.prompt.multi_select("Select dietary preferences (select multiple with space-bar and press enter)", dietary_preferences).join(' ')
        self.save
    end


    def reset_password
        
        def confirm_pass(pass)
            
            check = User.prompt.mask("Please confirm password")
            if pass == check
                puts "password updated"
                self.password = pass
                self.save
            else
                puts "Passwords do not match"
                User.prompt.keypress("Press space or enter to continue", keys: [:space, :return])
                self.reset_password
            end
        end

        check = User.prompt.mask("Please enter your current password before making any changes:")
        if check == self.password
            new_pass = User.prompt.mask("Please enter a new password")
            confirm_pass(new_pass)
        else
            puts "inncorrect password"
        end
    end

    def secret_nuke
        input = User.prompt.select("#{self.first_name}, are you sure you want to delete account: #{self.username}?", ['Yes, delete me!', 'NO WAY!'])

        if input == 'Yes, delete me!'
            good_bye = " USER, #{self.username} is deleted".colorize(:red)
            User.destroy(self.id)
            puts good_bye
        else
            puts "Glad you stayed #{self.first_name}"
            self
        end
    end
    
    def view_favorites
        if FavoriteRecipe.all.select {|fr| fr.user_id == self.id}.length == 0
            puts "You don't have any favorites"
        else
            favorite_recipes = FavoriteRecipe.all.select {|fr| fr.user_id == self.id}
            recipe_names = favorite_recipes.map{|fr| fr.recipe.name}

            input = User.prompt.select('Here are your favorties:', recipe_names)

            found_favorite_recipe = favorite_recipes.find{|fr| fr.recipe.name == input}
            self.format_recipe(found_favorite_recipe.recipe)
            unfavorite_recipe_names(found_favorite_recipe)
        end
    end
    
    # ----------------------PARSERS/INTERFACE----------------------------------------------------------
    def recipe_viewer(results)
        recipes = results.sample(1200)
   
        
        recipe_names = recipes.map{|recipe| recipe.name}.uniq
        input = User.prompt.select('Here are the recipes you can choose:', recipe_names)
        
        found_recipe = recipes.find{|recipe| recipe.name == input}
        self.favorite_a_recipe(found_recipe)        
    end
    
    def recipe_viewer_for_fav(results)
        recipes = results.take(10)
        recipe_names = recipes.map{|recipe| recipe.name}.uniq
        input = User.prompt.select('Here are the top most favorited recipes by all FitBUD users:', recipe_names)
        
        found_recipe = recipes.find{|recipe| recipe.name == input}
        self.favorite_a_recipe(found_recipe)        
    end

    def format_recipe(found_recipe)
        puts "Recipe: ".colorize(:light_cyan).bold + "#{found_recipe.name.colorize(:magenta)}".underline
        puts "Image Link: ".colorize(:light_cyan).bold + "#{found_recipe.image.colorize(:magenta)}"
        puts "Recipe URL: ".colorize(:light_cyan).bold + "#{found_recipe.url.colorize(:magenta)}"
        puts "Ingredients: ".colorize(:light_cyan).bold + "#{found_recipe.ingredients.colorize(:yellow)}"
        puts "Calories: ".colorize(:light_cyan).bold + "#{found_recipe.calories.to_s.colorize(:magenta).bold}"
        puts "Cautions: ".colorize(:light_cyan).bold + "#{found_recipe.cautions.colorize(:magenta)}"
        puts "Health Labels: ".colorize(:light_cyan).bold + "#{found_recipe.health_labels.colorize(:magenta)}"
        puts "Diet: ".colorize(:light_cyan).bold + "#{found_recipe.diet_labels.colorize(:magenta)}"
        puts "Number of favorites: ".colorize(:light_cyan).bold + "#{found_recipe.favorite_recipes.count}".colorize(:red)
    end

    def unfavorite_recipe_names(found_favorite_recipe)
        input = User.prompt.select('Would you like to unfavorite this recipe?', ['Unfavorite!', 'Main Menu'])

        if input == 'Unfavorite!'
            # id = FavoriteRecipe.all.find{|fr| fr.user_id == self.id and fr.recipe_id == found_recipe.id}.id
            FavoriteRecipe.destroy(found_favorite_recipe.id)
            puts "#{found_favorite_recipe.recipe.name} has been removed."
        end
    end

    def favorite_a_recipe(found_recipe)
        self.format_recipe(found_recipe)
        input = User.prompt.select('Would you like to favorite this recipe?', ['Favorite!', 'Main Menu'])

        if input == 'Favorite!'
            duplicate = FavoriteRecipe.all.find {|fr| fr.recipe_id == found_recipe.id and fr.user_id == self.id}
            if duplicate
                puts "Recipe already favorited".colorize(:red).bold
            else 
                FavoriteRecipe.create(user_id: self.id, recipe_id: found_recipe.id)
                puts "#{found_recipe.name} has been favorited."
            end
        end
    end
end
