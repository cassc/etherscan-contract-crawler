// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SamuraiLegendsGifterV2.sol";

interface IGenericCrates {
  function mintCrate(address user) external;
}

/**
 * @title Upgradable contract that handles sending gifts of different types to all users in a single transaction.
 * @author Leo
 */
contract SamuraiLegendsGifterV3 is SamuraiLegendsGifterV2 {
  mapping(uint256 => address) public genericCrates;

  /**
   * @notice Mints a gift to a single user.
   * @param user User address.
   * @param id Gift id.
   */
  function mint(address user, uint256 id) internal virtual override {
    super.mint(user, id);

    if (genericCrates[id] != address(0)) {
      IGenericCrates(genericCrates[id]).mintCrate(user);
    }
  }

  /**
   * @notice Add or remove generic crates address.
   * @param id Generic crates address id.
   * @param _genericCrates Generic crates address.
   */
  function _setGenericCrates(uint256 id, address _genericCrates) private {
    require(id > 6, "SamuraiLegendsGifterV3::setGenericCrates: id can't be less than 7");
    genericCrates[id] = _genericCrates;
  }

  /**
   * @notice Batch add or remove generic crates address.
   * @param ids Array of generic crates address id.
   * @param _genericCrates Array of generic crates address.
   */
  function setGenericCrates(uint256[] calldata ids, address[] calldata _genericCrates) external onlyOwner {
    for (uint256 i = 0; i < ids.length; i += 1) {
      require(ids[i] > 6, "SamuraiLegendsGifterV3::setGenericCrates: id can't be less than 7");
      genericCrates[ids[i]] = _genericCrates[i];
    }
  }

  /**
   * @notice Batch activate or deactivate gift ids
   * @param ids Array of gift id numbers
   * @param values Array of activation value
   */
  function activateBatch(uint256[] calldata ids, bool[] calldata values) external onlyOwner {
    for (uint256 i = 0; i < ids.length; i += 1) {
      activated[ids[i]] = values[i];

      emit Activated(ids[i]);
    }
  }
}