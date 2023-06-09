// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

/// @title Controllable
abstract contract Controllable {
  /// @notice address => is controller.
  mapping(address => bool) private _isController;
  /// @notice Require the caller to be a controller.
  modifier onlyController() {
    require(_isController[msg.sender], "Controllable: Caller is not a controller");
    _;
  }

  /// @notice Check if `addr` is a controller.
  function isController(address addr) public view returns (bool) {
    return _isController[addr];
  }

  /// @notice Set the `addr` controller status to `status`.
  function _setController(address addr, bool status) internal {
    _isController[addr] = status;
  }
}