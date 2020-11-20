class Recipe < ActiveRecord::Base
    has_many :favorite_recipes
    has_many :users, through: :favorite_recipes
 
    def self.top_users
        recipe_hash = {}
        self.all.each do |recipe|
            recipe_hash[recipe] = recipe.users.count 
        end
        sorted_hash = recipe_hash.sort_by {|name, user_count| user_count}.reverse
    end
end 


