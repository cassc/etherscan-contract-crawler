// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

/******************************************************************************\
* Author: Evert Kors <[email protected]> (https://twitter.com/evert0x)
* Sherlock Protocol: https://sherlock.xyz
/******************************************************************************/

import '@openzeppelin/contracts/access/Ownable.sol';

import '../../interfaces/strategy/INode.sol';
import '../../interfaces/strategy/INode.sol';
import './BaseNode.sol';

// Interface used by the MasterStrategy, the contract core will reference as `yieldStrategy`
abstract contract BaseMaster is IMaster, BaseNode {
  // ChildNode
  INode public override childOne;

  /// @notice Verify if `_newChild` is able to replace `_currentChild` without doing same parent check
  /// @param _currentChild Node that is the current child
  /// @param _newChild Node that is the new child
  function _verifySetChildSkipParentCheck(INode _currentChild, INode _newChild) internal {
    if (address(_newChild) == address(0)) revert ZeroArg();
    if (_newChild.setupCompleted() == false) revert SetupNotCompleted(_newChild);

    if (_newChild == _currentChild) revert InvalidArg();
    if (core != _newChild.core()) revert InvalidCore();
    if (want != _newChild.want()) revert InvalidWant();
  }

  /// @notice Verify if `_newChild` is able to replace `_currentChild`
  /// @param _currentChild Node that is the current child
  /// @param _newChild Node that is the new child
  function _verifySetChild(INode _currentChild, INode _newChild) internal {
    _verifySetChildSkipParentCheck(_currentChild, _newChild);
    // NOTE this check is basically one here for the `updateChild` call in splitter
    if (address(_newChild.parent()) != address(this)) revert InvalidParent();
  }

  /// @notice Set childOne in storage
  /// @param _currentChild The `childOne` currently stored
  /// @param _newChild The `childOne` that is stored after this call
  function _setChildOne(INode _currentChild, INode _newChild) internal {
    childOne = _newChild;
    emit ChildOneUpdate(_currentChild, _newChild);
  }

  /// @notice Set initial childOne
  /// @param _newChild Address of the initial child
  function setInitialChildOne(INode _newChild) external override onlyOwner {
    if (address(childOne) != address(0)) revert InvalidState();

    _verifySetChild(INode(address(0)), _newChild);
    _setChildOne(INode(address(0)), _newChild);
  }
}