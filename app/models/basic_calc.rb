class BasicCalc
    def self.inches_to_cm(inches)
        inches= inches.to_i
        cm = inches * 2.5
    end

    def self.pounds_to_kg(pounds)
        pounds = pounds.to_i
        kg = pounds / 2.2
    end
end