// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

contract Ownable {
  address private _convenienceOwner;

  event OwnershipSet(address indexed previousOwner, address indexed newOwner);

  /// @notice returns the address of the current _convenienceOwner
  /// @dev not used for access control, used by services that require a single owner account
  /// @return _convenienceOwner address
  function owner() public view virtual returns (address) {
    return _convenienceOwner;
  }

  /// @notice Set the _convenienceOwner address
  /// @dev not used for access control, used by services that require a single owner account
  /// @param newOwner address of the new _convenienceOwner
  function _setOwnership(address newOwner) internal virtual {
    address oldOwner = _convenienceOwner;
    _convenienceOwner = newOwner;
    emit OwnershipSet(oldOwner, newOwner);
  }

  /// @notice This empty reserved space is put in place to allow future versions to add new
  /// variables without shifting down storage in the inheritance chain.
  /// See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
  uint256[100] private __gap;
}