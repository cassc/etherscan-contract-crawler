// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

/******************************************************************************\
* Author: Evert Kors <[email protected]> (https://twitter.com/evert0x)
* Sherlock Protocol: https://sherlock.xyz
/******************************************************************************/

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/security/Pausable.sol';

import '../../interfaces/strategy/INode.sol';
import './BaseMaster.sol';

// Interface used by every splitter
abstract contract BaseSplitter is BaseMaster, ISplitter {
  using SafeERC20 for IERC20;
  // ChildNode
  INode public override childTwo;

  /*//////////////////////////////////////////////////////////////
                        TREE STRUCTURE LOGIC
  //////////////////////////////////////////////////////////////*/

  /// @param _initialParent The initial parent of this node
  /// @param _initialChildOne The initial childOne of this node
  /// @param _initialChildTwo The initial childTwo of this node
  constructor(
    IMaster _initialParent,
    INode _initialChildOne,
    INode _initialChildTwo
  ) BaseNode(_initialParent) {
    if (address(_initialChildOne) != address(0)) {
      _verifySetChildSkipParentCheck(INode(address(0)), _initialChildOne);
      _setChildOne(INode(address(0)), _initialChildOne);
    }

    if (address(_initialChildTwo) != address(0)) {
      _verifySetChildSkipParentCheck(INode(address(0)), _initialChildTwo);
      _setChildTwo(INode(address(0)), _initialChildTwo);
    }
  }

  /// @notice Check if this splitter is a master node
  /// @dev This implementation has two childs, it can never be a master (needs one child)
  function isMaster() external view override returns (bool) {
    return false;
  }

  /// @notice Check if this splitter completed it's setup
  /// @return completed Boolean indicating if setup is completed
  function setupCompleted() external view override returns (bool completed) {
    (completed, , ) = _setupCompleted();
  }

  /// @notice Check if this splitter completed it's setup
  /// @return completed Boolean indicating if setup is completed
  /// @return _childOne ChildOne read from storage
  /// @return _childTwo ChildTwo read from storage
  function _setupCompleted()
    internal
    view
    returns (
      bool completed,
      INode _childOne,
      INode _childTwo
    )
  {
    _childOne = childOne;
    _childTwo = childTwo;

    completed = address(_childOne) != address(0) && address(_childTwo) != address(0);
  }

  /// @notice Replace this splitter
  /// @param _node Splitter to be replaced by
  /// @dev only callable by owner
  /// @dev Same as `replace()`
  function replaceForce(INode _node) external virtual override {
    replace(_node);
    emit ForceReplace();
  }

  /// @notice Replace this splitter
  /// @param __newNode Splitter to be replaced by
  /// @dev only callable by owner
  function replace(INode __newNode) public virtual override onlyOwner {
    // Get childs from storage
    (bool completed, INode _childOne, INode _childTwo) = _setupCompleted();
    // Check if setup of this is completed
    if (completed == false) revert SetupNotCompleted(INode(address(this)));

    // Use ISplitter interface
    ISplitter _newNode = ISplitter(address(__newNode));

    // Check if same childs are used in `_newNode`
    if (_newNode.childOne() != _childOne) revert InvalidChildOne();
    if (_newNode.childTwo() != _childTwo) revert InvalidChildTwo();

    // Replace this with `_newNode`
    _replace(_newNode);

    // Make sure children have reference to `_newNode`
    _childOne.updateParent(_newNode);
    _childTwo.updateParent(_newNode);
  }

  /// @notice Get notified by child that it wants to be replaced by `_newChild`
  /// @param _newChild address of new child
  function updateChild(INode _newChild) external virtual override {
    // Get childs from storage
    (bool completed, INode _childOne, INode _childTwo) = _setupCompleted();
    // Check if setup of this is completed
    if (completed == false) revert SetupNotCompleted(INode(address(this)));

    // Is sender childOne?
    if (msg.sender == address(_childOne)) {
      // Can't have duplicate childs
      if (_newChild == _childTwo) revert InvalidArg();

      // Check if we are able to update
      _verifySetChild(_childOne, _newChild);
      // Execute update
      _setChildOne(_childOne, _newChild);
    } else if (msg.sender == address(_childTwo)) {
      // Is sender childTwo?

      // Can't have duplicate childs
      if (_newChild == _childOne) revert InvalidArg();

      // Check if we are able to update
      _verifySetChild(_childTwo, _newChild);
      // Execute update
      _setChildTwo(_childTwo, _newChild);
    } else {
      // Sender wasn't actually a child
      revert SenderNotChild();
    }
  }

  /// @notice Get notified by child that it is removed
  function childRemoved() external virtual override {
    // Get childs from storage
    (bool completed, INode _childOne, INode _childTwo) = _setupCompleted();
    // Check if setup of this is completed
    if (completed == false) revert SetupNotCompleted(INode(address(this)));

    // Is sender childOne?
    if (msg.sender == address(_childOne)) {
      // Notify childTwo that it's sibling has been removed
      _childTwo.siblingRemoved();
      // Tell parent to make a relationship with our non removed child
      parent.updateChild(_childTwo);

      // Declare removed child obsolete
      emit Obsolete(_childOne);
    } else if (msg.sender == address(_childTwo)) {
      // Notify childOne that it's sibling has been removed
      _childOne.siblingRemoved();
      // Tell parent to make a relationship with our non removed child
      parent.updateChild(_childOne);

      // Declare removed child obsolete
      emit Obsolete(_childTwo);
    } else {
      revert SenderNotChild();
    }

    // Declare address(this) obsolete
    emit Obsolete(INode(address(this)));
  }

  /// @notice Set childTwo in storage
  /// @param _currentChild The `childTwo` currently stored
  /// @param _newChild The `childTwo` that is stored after this call
  function _setChildTwo(INode _currentChild, INode _newChild) internal {
    childTwo = _newChild;
    emit ChildTwoUpdate(_currentChild, _newChild);
  }

  /// @notice Set initial childTwo
  /// @param _newChild Address of the initial child
  function setInitialChildTwo(INode _newChild) external override onlyOwner {
    if (address(childTwo) != address(0)) revert InvalidState();

    _verifySetChild(INode(address(0)), _newChild);
    _setChildTwo(INode(address(0)), _newChild);
  }

  /*//////////////////////////////////////////////////////////////
                        YIELD STRATEGY LOGIC
  //////////////////////////////////////////////////////////////*/

  // Internal variables to cache balances during runtime
  // Will always be 0 (except during runtime)
  uint256 internal cachedChildOneBalance;
  uint256 internal cachedChildTwoBalance;

  /// @notice Cache balances of childs in storage
  /// @notice Can only be called by parent node
  /// @dev It will first tell childs to cache their balances
  /// @dev Cache is built up from the bottom of the tree
  /// @dev As the chain returns when the bottom (strategies) are being called
  function prepareBalanceCache() external override onlyParent returns (uint256) {
    // Query balance of childs
    uint256 _cachedChildOneBalance = childOne.prepareBalanceCache();
    uint256 _cachedChildTwoBalance = childTwo.prepareBalanceCache();

    // Write balances to storage
    // It's "cached" as we expect/assume `expireBalanceCache()` will be called in the same transaction
    cachedChildOneBalance = _cachedChildOneBalance;
    cachedChildTwoBalance = _cachedChildTwoBalance;

    // Return the balance of this splitter to parent
    // The balance this splitter represent is the sum of the childs
    return _cachedChildOneBalance + _cachedChildTwoBalance;
  }

  /// @notice Expired cached balances in storage
  /// @notice Can only be called by parent node
  /// @dev It assumes `prepareBalanceCache()` was called before
  function expireBalanceCache() external override onlyParent {
    // Set cached balances back to the value of the start of the transaction (--> 0)
    delete cachedChildOneBalance;
    delete cachedChildTwoBalance;
  }

  /// @notice Withdraw all funds
  /// @notice Can only be called by admin
  /// @notice Not implemented
  /// @return amount Amount of USDC withdrawn
  /// @dev More context: https://github.com/sherlock-protocol/sherlock-v2-core/issues/24
  function withdrawAllByAdmin() external override onlyOwner returns (uint256 amount) {
    revert NotImplemented(msg.sig);
  }

  /// @notice Withdraw `_amount` funds
  /// @notice Can only be called by admin
  /// @notice Not implemented
  /// @dev More context: https://github.com/sherlock-protocol/sherlock-v2-core/issues/24
  function withdrawByAdmin(uint256 _amount) external override onlyOwner {
    revert NotImplemented(msg.sig);
  }

  function _withdrawAll() internal virtual override returns (uint256 amount) {
    // Children will withdraw to core()
    amount = childOne.withdrawAll();
    amount += childTwo.withdrawAll();
  }

  function _balanceOf() internal view virtual override returns (uint256 amount) {
    amount = childOne.balanceOf();
    amount += childTwo.balanceOf();
  }
}