// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LibDiamond} from "../diamond/LibDiamond.sol";
import {StorageSlot} from "./StorageSlot.sol";

abstract contract Proxy {
  bytes32 internal constant IMPLEMENTATION_SLOT =
    bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1);
  event Upgraded(address indexed implementation);

  function implementation() public view returns (address) {
    return _getImplementation();
  }

  /**
   * @dev Returns the current implementation address.
   */
  function _getImplementation() internal view returns (address) {
    return StorageSlot.getAddressSlot(IMPLEMENTATION_SLOT).value;
  }

  /**
   * @dev Stores a new address in the EIP1967 implementation slot.
   */
  function _setImplementation(address newImplementation) internal {
    LibDiamond.enforceHasContractCode(newImplementation);
    StorageSlot.getAddressSlot(IMPLEMENTATION_SLOT).value = newImplementation;
    emit Upgraded(newImplementation);
  }
}