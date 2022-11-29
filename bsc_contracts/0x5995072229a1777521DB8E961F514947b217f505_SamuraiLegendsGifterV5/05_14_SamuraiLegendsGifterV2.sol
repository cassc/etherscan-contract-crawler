// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SamuraiLegendsGifterV1.sol";

interface ISpecialCrates {
  function mintCrate(address user, uint256 crateType) external;
}

/**
 * @title Upgradable contract that handles sending gifts of different types to all users in a single transaction.
 * @author Leo
 */
contract SamuraiLegendsGifterV2 is SamuraiLegendsGifterV1 {
  ISpecialCrates public specialCrates;

  /**
   * @notice Mints a gift to a single user.
   * @param user User address.
   * @param id Gift id.
   */
  function mint(address user, uint256 id) internal virtual override {
    super.mint(user, id);

    if (id == 4) {
      // monk
      specialCrates.mintCrate(user, 0);
    } else if (id == 5) {
      // ninja
      specialCrates.mintCrate(user, 1);
    } else if (id == 6) {
      // archer
      specialCrates.mintCrate(user, 2);
    }
  }

  /**
   * @notice Updates special crates address.
   * @param specialCrates_ Special crates address.
   */
  function setSpecialCrates(address specialCrates_) external onlyOwner {
    specialCrates = ISpecialCrates(specialCrates_);
  }
}