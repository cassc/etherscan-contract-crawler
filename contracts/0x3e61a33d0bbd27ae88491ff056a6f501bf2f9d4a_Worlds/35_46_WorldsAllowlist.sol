// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.18;

import { MAX_WORLD_TAKE_RATE } from "../shared/Constants.sol";

import { WorldsAllowlistBySeller } from "./WorldsAllowlistBySeller.sol";

error WorldsAllowlist_Take_Rate_Above_Max(uint256 maxTakeRate);

/**
 * @title Coordinates worlds permissions across potentially several allowlist types.
 * @author HardlyDifficult
 */
abstract contract WorldsAllowlist is WorldsAllowlistBySeller {
  /// @notice Reverts if a requested inventory addition is not allowed.
  modifier onlyAllowedInventoryAddition(uint256 worldId, uint16 takeRateInBasisPoints) {
    _requireMinted(worldId);
    if (takeRateInBasisPoints > MAX_WORLD_TAKE_RATE) {
      revert WorldsAllowlist_Take_Rate_Above_Max(MAX_WORLD_TAKE_RATE);
    }

    _authorizeBySeller(worldId, takeRateInBasisPoints, _msgSender());
    _;
  }

  /**
   * @notice This empty reserved space is put in place to allow future versions to add new variables without shifting
   * down storage in the inheritance chain. See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   * @dev This file uses a total of 10,000 slots.
   */
  uint256[10_000] private __gap;
}