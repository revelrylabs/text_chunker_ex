<?php

class PetShop
{
    /**
     * Represents a pet shop with inventory and sales functionality.
     */
    private $inventory = [];

    public function addPet($petType, $quantity)
    {
        if (isset($this->inventory[$petType])) {
            $this->inventory[$petType] += $quantity;
        } else {
            $this->inventory[$petType] = $quantity;
        }
    }

    public function sellPet($petType, $quantity)
    {
        if (($this->inventory[$petType] ?? 0) >= $quantity) {
            $this->inventory[$petType] -= $quantity;
            return true;
        }

        return false;
    }

    private function restockThreshold()
    {
        return 5;
    }
}
