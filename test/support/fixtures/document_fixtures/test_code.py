class PetShop:
    """Represents a pet shop with inventory and sales functionality."""

    def __init__(self, name):
        self.name = name
        self.inventory = {}

    def add_pet(self, pet_type, quantity):
        """Adds a specified quantity of a pet type to the inventory."""
        if pet_type in self.inventory:
            self.inventory[pet_type] += quantity
        else:
            self.inventory[pet_type] = quantity

    def sell_pet(self, pet_type, quantity):
        """Sells a specified quantity of a pet type."""
        if pet_type in self.inventory and self.inventory[pet_type] >= quantity:
            self.inventory[pet_type] -= quantity
            return True
        else:
            return False

    def get_pet_count(self, pet_type):
        """Returns the current count of a specific pet type."""
        return self.inventory.get(pet_type, 0)
