// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SamuraiLegendsGifterV3.sol";

/**
 * @title Upgradable contract that handles sending gifts of different types to all users in a single transaction.
 * @author Leo
 */
contract SamuraiLegendsGifterV4 is SamuraiLegendsGifterV3 {
  mapping(address => mapping(uint256 => bool)) public openedMysteryBox;

  /**
   * @notice Open a mystery box
   * @param user Mystery box owner
   * @param mysteryBox Mystery box address
   * @param mysteryBoxId Mystery box address tokenId
   * @param ids Crate id to be sent
   */
  function openMysteryBox(
    address user,
    address mysteryBox,
    uint256 mysteryBoxId,
    uint256[] calldata ids
  ) external onlyOwner {
    require(openedMysteryBox[mysteryBox][mysteryBoxId] == false, "SamuraiLegendsGifter::openMysteryBox: mystery box already opened");

    openedMysteryBox[mysteryBox][mysteryBoxId] = true;

    for (uint256 i = 0; i < ids.length; i++) {
      mint(user, ids[i]);
    }

    emit OpenMysteryBox(user, mysteryBox, mysteryBoxId, ids);
  }

  event OpenMysteryBox(address indexed user, address indexed mysteryBox, uint256 indexed mysteryBoxId, uint256[] ids);
}