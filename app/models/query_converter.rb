def query_convert (search, max_cals = 1200)
    query = RestClient.get("https://api.edamam.com/search?q=#{search.to_s}&from=0&to=100&app_id=51cb729e&app_key=f0fd4266b17b0ecf4b45f1b6ac0c0ad1&calories=0-#{max_cals}")
    parsed_data = JSON.parse(query)
    max_cals.to_s

    parsed_data["hits"].each do |hit|
        recipe = hit["recipe"]
        name = recipe["label"]
        image = recipe["image"]
        url = recipe["shareAs"]
        ingredients = recipe["ingredientLines"].join(', ')
        cautions = recipe["cautions"].join(' ')
        diet_labels = recipe["dietLabels"].join(' ')
        health_labels = recipe["healthLabels"].join(' ')
        calories = recipe["calories"]
        time = recipe["totalTime"]
        duplicate_check = Recipe.all.find{|rec| rec.name == name and rec.image == image and rec.url == url}
        if duplicate_check == nil
            found_recipe = Recipe.create(name: name, image: image, url: url, ingredients: ingredients, cautions: cautions, diet_labels: diet_labels, health_labels: health_labels, calories: calories, time: time)
        end
    end 
end

