// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./IWorldsEscrow.sol";
import "./IWorldsRental.sol";

library WorldsRentalStorage {
  bytes32 private constant STORAGE_SLOT = keccak256("slot.worlds.rental");

  struct Layout {
    address paymentTokenAddress;
    IWorldsEscrow WorldsEscrow;
    IWorldsRental.WorldRentInfo[10001] worldRentInfo; // Worlds tokenId is in N [1,10000]
    mapping (address => uint) rentCount; // count of rented worlds per tenant
    mapping (address => mapping(uint => uint)) rentedWorlds; // enumerate rented worlds per tenant
    mapping (uint => uint) rentedWorldsIndex; // tokenId to index in _rentedWorlds[tenant]
  }

  function layout() internal pure returns (Layout storage _layout) {
    bytes32 slot = STORAGE_SLOT;

    assembly {
      _layout.slot := slot
    }
  }
}