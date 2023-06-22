// SPDX-License-Identifier: MIT

pragma solidity >=0.6.8;

import '../interfaces/IManageable.sol';

abstract
contract Manageable is IManageable {
  address public manager;
  address public pendingManager;

  constructor(address _manager) public {
    require(_manager != address(0), 'manageable/manager-should-not-be-zero-address');
    manager = _manager;
  }

  function _setPendingManager(address _pendingManager) internal {
    require(_pendingManager != address(0), 'manageable/pending-manager-should-not-be-zero-addres');
    pendingManager = _pendingManager;
    emit PendingManagerSet(_pendingManager);
  }

  function _acceptManager() internal {
    manager = pendingManager;
    pendingManager = address(0);
    emit ManagerAccepted();
  }

  modifier onlyManager {
    require(msg.sender == manager, 'manageable/only-manager');
    _;
  }

  modifier onlyPendingManager {
    require(msg.sender == pendingManager, 'manageable/only-pending-manager');
    _;
  }
}