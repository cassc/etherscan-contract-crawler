// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

interface ISamuraiCrates {
  function mintCrate(address user, uint256[] memory cardIds) external;
}

/**
 * @title Upgradable contract that handles sending gifts of different types to all users in a single transaction.
 * @author Leo
 */
contract SamuraiLegendsGifterV1 is Initializable, OwnableUpgradeable {
  mapping(uint256 => bool) public activated;
  ISamuraiCrates public samuraiCrates;

  /**
   * @notice Initializes the upgradable contract.
   */
  function initialize() public virtual initializer {
    __Ownable_init();
  }

  /**
   * @notice Mints gifts to all users in a single transaction.
   * @param users Users addresses.
   * @param ids Gift id of every user.
   */
  function mintForAll(address[] calldata users, uint256[] calldata ids) external onlyOwner {
    require(users.length == ids.length, "users and ids have different length");

    for (uint256 i = 0; i < users.length; i++) {
      mint(users[i], ids[i]);
    }

    emit MintForAll(users, ids);
  }

  /**
   * @notice Mints a gift to a single user.
   * @param user User address.
   * @param id Gift id.
   */
  function mint(address user, uint256 id) internal virtual {
    require(activated[id], "gift id isn't active yet");

    if (id == 0) {
      // 0*
      uint256[] memory ids = new uint256[](3);
      ids[0] = 5000;
      ids[1] = 5000;
      ids[2] = 5000;
      samuraiCrates.mintCrate(user, ids);
    } else if (id == 1) {
      // 1*
      uint256[] memory ids = new uint256[](3);
      ids[0] = 5000;
      ids[1] = 5000;
      ids[2] = 1;
      samuraiCrates.mintCrate(user, ids);
    } else if (id == 2) {
      // 2*
      uint256[] memory ids = new uint256[](3);
      ids[0] = 5000;
      ids[1] = 1;
      ids[2] = 1;
      samuraiCrates.mintCrate(user, ids);
    } else if (id == 3) {
      // 3*
      uint256[] memory ids = new uint256[](3);
      ids[0] = 1;
      ids[1] = 1;
      ids[2] = 1;
      samuraiCrates.mintCrate(user, ids);
    }
  }

  /**
   * @notice Activate or deactivate a gift id
   * @param id Gift id number
   * @param value_ Activation value
   */
  function activate(uint256 id, bool value_) external onlyOwner {
    activated[id] = value_;

    emit Activated(id);
  }

  /**
   * @notice Updates samurai crates address.
   * @param samuraiCrates_ Samurai crates address.
   */
  function setSamuraiCrates(address samuraiCrates_) external onlyOwner {
    samuraiCrates = ISamuraiCrates(samuraiCrates_);
  }

  event MintForAll(address[] users, uint256[] ids);
  event Activated(uint256 id);
}