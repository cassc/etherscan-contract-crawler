// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "./ConfirmedOwner.sol";
import "../interfaces/ReadWriteAccessControllerInterface.sol";

/**
 * @title ReadWriteAccessController
 * @notice Grants read and write permissions to the aggregator
 * @dev does not make any special permissions for EOAs, see
 * ReadAccessController for that.
 */
contract AggregatorReadWriteAccessController is ReadWriteAccessControllerInterface, ConfirmedOwner(msg.sender) {
  mapping(address => bool) internal s_readAccessList;
  mapping(address => bool) internal s_writeAccessList;

  event ReadAccessAdded(address user, address sender);
  event ReadAccessRemoved(address user, address sender);
  event WriteAccessAdded(address user, address sender);
  event WriteAccessRemoved(address user, address sender);

  /**
   * @notice Returns the read access of an address
   * @param user The address to query
   */
  function hasReadAccess(address user) external view virtual override returns (bool) {
    return s_readAccessList[user];
  }

  /**
   * @notice Returns the write access of an address
   * @param user The address to query
   */
  function hasWriteAccess(address user) external view virtual override returns (bool) {
    return s_writeAccessList[user];
  }

  /**
   * @notice Revokes read access of a address if  already added
   * @param user The address to remove
   */
  function removeReadAccess(address user) external onlyOwner {
    _removeReadAccess(user);
  }

  /**
   * @notice Provide read access to a address
   * @param user The address to add
   */
  function addReadAccess(address user) external onlyOwner {
    _addReadAccess(user);
  }

  /**
   * @notice Revokes write access of a address if already added
   * @param user The address to remove
   */
  function removeWriteAccess(address user) external onlyOwner {
    _removeWriteAccess(user);
  }

  /**
   * @notice Provide write access to a address
   * @param user The address to add
   */
  function addWriteAccess(address user) external onlyOwner {
    _addWriteAccess(user);
  }

  function _addReadAccess(address user) internal {
    if (!s_readAccessList[user]) {
      s_readAccessList[user] = true;
      emit ReadAccessAdded(user, msg.sender);
    }
  }

  function _removeReadAccess(address user) internal {
    if (s_readAccessList[user]) {
      s_readAccessList[user] = false;
      emit ReadAccessRemoved(user, msg.sender);
    }
  }

  function _addWriteAccess(address user) internal {
    if (!s_writeAccessList[user]) {
      s_writeAccessList[user] = true;
      emit WriteAccessAdded(user, msg.sender);
    }
  }

  function _removeWriteAccess(address user) internal {
    if (s_writeAccessList[user]) {
      s_writeAccessList[user] = false;
      emit WriteAccessRemoved(user, msg.sender);
    }
  }
}