// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
pragma abicoder v2;

// OpenZeppelin v4
import { TreasuryOld } from "../treasury/TreasuryOld.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title Treasury Migration
 * @author Railgun Contributors
 * @notice Migrates treasury funds from one contract to another
 */
contract TreasuryMigration {
  // Old treasury contract
  TreasuryOld immutable public oldTreasury;

  // New treasury contract
  address payable immutable public newTreasury;

  /**
   * @notice Set treasury addresses
   * @param _oldTreasury - old treasury to migrate from
   * @param _newTreasury - new treasury to migrate to
   */
  constructor(TreasuryOld _oldTreasury, address payable _newTreasury) {
    oldTreasury = _oldTreasury;
    newTreasury = _newTreasury;
  }

  /**
   * @notice Migrates ETH from old treasury
   */
  function migrateETH() external {
    // Transfer all ETH to new treasury
    oldTreasury.transferETH(newTreasury, address(oldTreasury).balance);
  }

  /**
   * @notice Migrates ERC20s from old treasury
   */
  function migrateERC20(IERC20[] calldata _tokens) external {
    // Loop through each token
    for (uint256 i = 0; i < _tokens.length; i += 1) {
      // Fetch balance
      uint256 balance = _tokens[i].balanceOf(address(oldTreasury));

      // Transfer all to new treasury
      oldTreasury.transferERC20(_tokens[i], newTreasury, balance);
    }
  }
}