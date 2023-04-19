// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {IRoyaltyGuardDeadmanTrigger} from "../extensions/IRoyaltyGuardDeadmanTrigger.sol";
import {IRoyaltyGuard, RoyaltyGuard} from "../RoyaltyGuard.sol";

import {EnumerableSet} from "openzeppelin-contracts/utils/structs/EnumerableSet.sol";
import {ERC165} from "openzeppelin-contracts/utils/introspection/ERC165.sol";

/// @title RoyaltyGuard
/// @author highland, koloz, van arman
/// @notice An abstract contract with the necessary functions, structures, modifiers to ensure royalties are paid.
/// @dev Inherriting this contract requires implementing {hasAdminPermission} and connecting the desired functions to the {checkList} modifier.
abstract contract RoyaltyGuardDeadmanTrigger is IRoyaltyGuardDeadmanTrigger, RoyaltyGuard {

  /*//////////////////////////////////////////////////////////////////////////
                          Private Contract Storage
  //////////////////////////////////////////////////////////////////////////*/

  uint256 private deadmanListTriggerAfterDatetime;

  /*//////////////////////////////////////////////////////////////////////////
                            Admin Functions
  //////////////////////////////////////////////////////////////////////////*/

  /// @dev Only the contract owner can call this function.
  /// @inheritdoc IRoyaltyGuardDeadmanTrigger
  function setDeadmanListTriggerRenewalDuration(uint256 _numYears) external virtual onlyAdmin {
    _setDeadmanTriggerRenewalInYears(_numYears);
  }

  /*//////////////////////////////////////////////////////////////////////////
                          Public Write Functions
  //////////////////////////////////////////////////////////////////////////*/

  /// @dev Can only be called if deadmanListTriggerAfterDatetime is in the past.
  /// @inheritdoc IRoyaltyGuardDeadmanTrigger
  function activateDeadmanListTrigger() external virtual {
    if (deadmanListTriggerAfterDatetime > block.timestamp) revert IRoyaltyGuardDeadmanTrigger.DeadmanTriggerStillActive();
    _setListType(IRoyaltyGuard.ListType.OFF);
    emit DeadmanTriggerActivated(msg.sender);
  }

  /*//////////////////////////////////////////////////////////////////////////
                          Public Read Functions
  //////////////////////////////////////////////////////////////////////////*/

  /// @inheritdoc IRoyaltyGuardDeadmanTrigger
  function getDeadmanTriggerAvailableDatetime() external virtual view returns (uint256) {
    return deadmanListTriggerAfterDatetime;
  }

  /*//////////////////////////////////////////////////////////////////////////
                            Internal Functions
  //////////////////////////////////////////////////////////////////////////*/

  /// @dev Internal method to set deadman trigger datetime. Main usage is constructor.
  function _setDeadmanTriggerRenewalInYears(uint256 _numYears) internal {
    uint256 newDatetime = block.timestamp + _numYears * 365 days;
    emit DeadmanTriggerDatetimeUpdated(msg.sender, deadmanListTriggerAfterDatetime, newDatetime);
    deadmanListTriggerAfterDatetime = newDatetime;
  }
}