// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library FruitFarm {
  uint256 private constant STEM_COUNT = 2;
  uint256 private constant LEAF_COUNT = 3;
  uint256 private constant STUFF_COUNT = 7;

  uint256 public constant FRUIT_COUNT = STEM_COUNT * LEAF_COUNT * STUFF_COUNT * STUFF_COUNT;


  function harvest(uint256 fruitId) public pure returns (string memory) {
    return _getFruit(fruitId - 1);
  }

  function _getFruit(uint256 id) internal pure returns (string memory) {
    string[STEM_COUNT] memory stems = [
      unicode"stemR\n",
      unicode"stemL\n"
    ];
    string[LEAF_COUNT] memory leaves = [
      unicode"1 leaf\n",
      unicode"2 leaves\n",
      unicode"flower\n"
    ];
    string[STUFF_COUNT] memory stuff = [
      unicode"coconut\n",
      unicode"passion fruit\n",
      unicode"strawberry\n",
      unicode"apple\n",
      unicode"orange\n",
      unicode"watermelon\n",
      unicode"kiwi\n"
    ];
    uint256 pos1 = id / (FRUIT_COUNT / STEM_COUNT);
    uint256 rem = id % (FRUIT_COUNT/ STEM_COUNT);
    uint256 pos2 = rem / (FRUIT_COUNT/ (STEM_COUNT * LEAF_COUNT));
    rem = rem % (FRUIT_COUNT/ (STEM_COUNT * LEAF_COUNT));
    uint256 pos3 = rem / (FRUIT_COUNT/ (STEM_COUNT * LEAF_COUNT * STUFF_COUNT));
    rem = rem % (FRUIT_COUNT / (STEM_COUNT * LEAF_COUNT * STUFF_COUNT));
    uint256 pos4 = rem;

    return string(abi.encodePacked(stems[pos1], leaves[pos2], stuff[pos3], stuff[pos4]));

  }
}