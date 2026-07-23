class PetShop
  ## Represents a pet shop with inventory and sales functionality.

  def initialize(name)
    @name = name
    @inventory = {}
  end

  def add_pet(pet_type, quantity)
    if @inventory.key?(pet_type)
      @inventory[pet_type] += quantity
    else
      @inventory[pet_type] = quantity
    end
  end

  def sell_pet(pet_type, quantity)
    if @inventory.fetch(pet_type, 0) >= quantity
      @inventory[pet_type] -= quantity
      true
    else
      false
    end
  end

  private

  def restock_threshold
    5
  end
end
