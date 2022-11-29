// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SamuraiLegendsGifterV4.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

/**
 * @title Upgradable contract that handles sending gifts of different types to all users in a single transaction.
 * @author Leo
 */
contract SamuraiLegendsGifterV5 is SamuraiLegendsGifterV4, AccessControlUpgradeable {
  bytes32 public constant OPENER_ROLE = keccak256("OPENER_ROLE");
  bool private accessControlInitialized;

  /**
   * @notice Initializes the upgradable contract.
   */
  function initializeAccessControl() external {
    require(!accessControlInitialized);
    accessControlInitialized = true;
    _grantRole(DEFAULT_ADMIN_ROLE, owner());
    _grantRole(OPENER_ROLE, owner());
  }

  /**
   * @notice Open a mystery box
   * @param user Mystery box owner
   * @param mysteryBox Mystery box address
   * @param mysteryBoxId Mystery box address tokenId
   * @param ids Crate id to be sent
   */
  function openMysteryBoxV2(
    address user,
    address mysteryBox,
    uint256 mysteryBoxId,
    uint256[] calldata ids
  ) external onlyRole(OPENER_ROLE) {
    require(openedMysteryBox[mysteryBox][mysteryBoxId] == false, "SamuraiLegendsGifter::openMysteryBoxV2: mystery box already opened");

    openedMysteryBox[mysteryBox][mysteryBoxId] = true;

    for (uint256 i = 0; i < ids.length; i++) {
      mint(user, ids[i]);
    }

    emit OpenMysteryBox(user, mysteryBox, mysteryBoxId, ids);
  }
}