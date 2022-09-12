// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.4;

interface HouseGameState {
    struct HouseInfo {
        Model model;
        uint256 incomePerDay;
        uint256 propertyDamage;
    }

    enum Model {
      TREE_HOUSE,
      TRAILER_HOUSE,
      CABIN,
      ONE_STORY_HOUSE,
      TWO_STORY_HOUSE,
      MANSION,
      CASTLE,
      UTILITY_BUILDING
    }
}