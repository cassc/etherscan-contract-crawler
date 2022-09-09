// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

error CallerIsNotController();
error NotOwnerOrController();

abstract contract Controllable is Ownable {
  /// @notice address => is controller.
  mapping(address => bool) private _isController;

  /// @notice Require the caller to be a controller.
  modifier onlyController() {
    if (!_isController[_msgSender()]) revert CallerIsNotController();
    _;
  }

  /// @notice Require the caller to be a controller or owner
    modifier onlyOwnerOrController() {
    if (!(owner() == _msgSender() || isController(_msgSender()))) revert NotOwnerOrController();
    _;
  }

  /// @notice Check if `addr` is a controller.
  function isController(address addr) public view returns (bool) {
    return _isController[addr];
  }

  /// @notice Set the `addr` controller status to `status`.
  function setControllers(address[] calldata addrs, bool status) external onlyOwner {
    for (uint256 i; i < addrs.length; i++) _isController[addrs[i]] = status;
  }
}