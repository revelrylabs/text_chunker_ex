<template>
  <section class="pet-shop">
    <h1>{{ title }}</h1>
    <table>
      <tr v-for="pet in pets" :key="pet.id">
        <td>{{ pet.name }}</td>
        <td>{{ pet.quantity }}</td>
      </tr>
    </table>
  </section>
</template>

<script>
export default {
  name: "PetShop",
  data() {
    return {
      title: "Pet Shop Inventory",
      pets: [],
    };
  },
  methods: {
    addPet(pet) {
      this.pets.push(pet);
    },
  },
};
</script>
