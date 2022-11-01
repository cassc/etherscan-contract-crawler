// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library LazyShoeDistribution {
    struct Shoe {
      mapping(uint=>uint) slots;
      uint size;
    }

    function lazyValue( Shoe storage shoe, uint index) private view returns (uint result) {
      result = shoe.slots[index];
      if (result == 0) {
        result = uint16(index) + 1;
      }
    }

    function pop( Shoe storage shoe, uint256 random) internal returns (uint result ) {
      uint lastIndex = shoe.size - 1;
      if (shoe.size == 1) {
        result = lazyValue(shoe, 0);
      } else {
        uint pickIndex = random % shoe.size;
        result = lazyValue(shoe, pickIndex);
        if (pickIndex < lastIndex) {
          shoe.slots[pickIndex] = lazyValue(shoe, lastIndex);
        }
      }

      shoe.slots[lastIndex] = 0;
      shoe.size--;
    }
}