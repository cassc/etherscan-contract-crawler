// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

/// @notice Ownable contract used to manage the SwapSHARO contract.
abstract contract Ownable {
  address private _owner;

  address public pendingOwner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /// @notice Initializes the contract setting the deployer as the initial owner.
  constructor() {
    _transferOwnership(msg.sender);
  }

  /// @notice Throws if called by any account other than the owner.
  modifier onlyOwner() {
    require(owner() == msg.sender, "Ownable: caller is not the owner");
    _;
  }

  /// @notice Returns the address of the current owner.
  function owner() public view returns (address) {
    return _owner;
  }

  /// @notice Leaves the contract without owner. It will not be possible to call `onlyOwner` modifier anymore.
  /// @param isRenounce: Boolean parameter with which you confirm renunciation of ownership
  function renounceOwnership(bool isRenounce) public onlyOwner {
    if (isRenounce) _transferOwnership(address(0));
  }

  /// @notice Transfers ownership of the contract to a new account.
  /// @param newOwner: The address of the new owner of the contract
  /// @param direct: Boolean parameter that will be used to change the owner of the contract directly
  function transferOwnership(address newOwner, bool direct) external onlyOwner {
    if (direct) {
      require(newOwner != address(0), "Ownable: zero address");
      require(
        newOwner != _owner,
        "Ownable: newOwner must be a different address than the current owner"
      );

      _transferOwnership(newOwner);
      pendingOwner = address(0);
    } else {
      pendingOwner = newOwner;
    }
  }

  /// @notice The `pendingOwner` should to confirm, if he wants to be the new owner of the contract.
  function claimOwnership() external {
    require(msg.sender == pendingOwner, "Ownable: caller != pending owner");

    _transferOwnership(pendingOwner);
    pendingOwner = address(0);
  }

  /// @notice Transfers ownership of the contract to a new account.
  /// @param newOwner: The address of the new owner of the contract
  function _transferOwnership(address newOwner) internal {
    _owner = newOwner;
    emit OwnershipTransferred(_owner, newOwner);
  }
}