class PetShop {
  constructor(name) {
      this.name = name;
      this.inventory = {};
  }

  addPet(petType, quantity) {
      if (this.inventory[petType]) {
          this.inventory[petType] += quantity;
      } else {
          this.inventory[petType] = quantity;
      }
  }

  sellPet(petType, quantity) {
      if (this.inventory[petType] && this.inventory[petType] >= quantity) {
          this.inventory[petType] -= quantity;
          return true;
      } else {
          return false;
      }
  }

  getPetCount(petType) {
      return this.inventory[petType] || 0; 
  }
}
