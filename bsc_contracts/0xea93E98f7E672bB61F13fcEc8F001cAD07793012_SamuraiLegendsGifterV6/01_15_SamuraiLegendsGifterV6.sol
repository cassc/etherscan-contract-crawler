// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SamuraiLegendsGifterV5.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

interface IMysteryBoxes {
  function mint(address user) external;
}

/**
 * @title Upgradable contract that handles sending gifts of different types to all users in a single transaction.
 * @author Leo
 */
contract SamuraiLegendsGifterV6 is SamuraiLegendsGifterV5 {
  mapping(uint256 => address) public mysteryBoxes;

  /**
   * @notice Mints a gift to a single user.
   * @param user User address.
   * @param id Gift id.
   */
  function mint(address user, uint256 id) internal virtual override {
    super.mint(user, id);

    if (mysteryBoxes[id] != address(0)) {
      IMysteryBoxes(mysteryBoxes[id]).mint(user);
    }
  }

  /**
   * @notice Add or remove mystery boxes address.
   * @param id Generic crates address id.
   * @param _mysteryBoxes Generic crates address.
   */
  function _setMysteryBoxes(uint256 id, address _mysteryBoxes) private {
    require(id > 6, "SamuraiLegendsGifterV6::setMysteryBoxes: id can't be less than 7");
    mysteryBoxes[id] = _mysteryBoxes;
  }

  /**
   * @notice Batch add or remove mystery boxes address.
   * @param ids Array of mystery boxes address id.
   * @param _mysteryBoxes Array of mystery boxes address.
   */
  function setMysteryBoxes(uint256[] calldata ids, address[] calldata _mysteryBoxes) external onlyOwner {
    for (uint256 i = 0; i < ids.length; i += 1) {
      require(ids[i] > 6, "SamuraiLegendsGifterV6::setMysteryBoxes: id can't be less than 7");
      mysteryBoxes[ids[i]] = _mysteryBoxes[i];
    }
  }
}