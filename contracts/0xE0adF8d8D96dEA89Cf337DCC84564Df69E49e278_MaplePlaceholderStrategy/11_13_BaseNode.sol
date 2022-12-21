// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

/******************************************************************************\
* Author: Evert Kors <[email protected]> (https://twitter.com/evert0x)
* Sherlock Protocol: https://sherlock.xyz
/******************************************************************************/

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

import '../../interfaces/strategy/INode.sol';

// Interface used by every node
abstract contract BaseNode is INode, Ownable {
  using SafeERC20 for IERC20;

  // Parent node
  IMaster public override parent;
  // Which token the strategy uses (USDC)
  IERC20 public immutable override want;
  // Reference to core (Sherlock.sol)
  address public immutable override core;

  /// @param _initialParent The initial parent of this node
  constructor(IMaster _initialParent) {
    if (address(_initialParent) == address(0)) revert ZeroArg();

    IERC20 _want = _initialParent.want();
    address _core = _initialParent.core();

    if (address(_want) == address(0)) revert InvalidWant();
    if (address(_core) == address(0)) revert InvalidCore();

    want = _want;
    core = _core;
    parent = _initialParent;

    emit ParentUpdate(IMaster(address(0)), _initialParent);
  }

  modifier onlyParent() {
    if (msg.sender != address(parent)) revert SenderNotParent();
    _;
  }

  /*//////////////////////////////////////////////////////////////
                        TREE STRUCTURE LOGIC
  //////////////////////////////////////////////////////////////*/

  /// @notice Replace this node to be a child of `_newParent`
  /// @param _newParent address of the new parent
  /// @dev Replace as child ensures that (this) is the child of the `_newParent`
  /// @dev It will also enfore a `_executeParentUpdate` to make that relation bi-directional
  /// @dev For the other child is does minimal checks, it only checks if it isn't the same as address(this)
  function replaceAsChild(ISplitter _newParent) external virtual override onlyOwner {
    /*
          m
          |
        this

          m
          |
          1
         / \
        z  this
    */

    // Gas savings
    IMaster _currentParent = parent;

    // Revert is parent is master
    // The master is always at the root of the tree
    if (_newParent.isMaster()) revert IsMaster();

    // Verify if the new parent has the right connections
    _verifyParentUpdate(_currentParent, _newParent);
    // Verify is childs of newParent are correct
    INode otherChild = _verifyNewParent(_newParent);

    // Revert if otherchild = 0
    // Revert if the other child has the right parent reference too
    // Check if `z` has the right parent (referencing comment on top function)
    if (otherChild.parent() != _newParent) revert InvalidParent();

    // Check if `_newParent` references our currentParent as their parent
    // Check if `m` == `1`.parent() (referencing comment on top function)
    if (_currentParent != _newParent.parent()) revert InvalidParent();

    // Make sure the parent recognizes the new child
    // Make sure `m` references `1` as it's child (referencing comment on top function)
    _currentParent.updateChild(_newParent);

    // Update parent
    _executeParentUpdate(_currentParent, _newParent);

    emit ReplaceAsChild();
  }

  /// @notice Replace parent of this node
  /// @param _newParent Address of the new parent
  /// @dev Only callable by current parent
  function updateParent(IMaster _newParent) external virtual override onlyParent {
    // Verify if the parent can be updated
    _verifyParentUpdate(IMaster(msg.sender), _newParent);
    _verifyNewParent(_newParent);

    // Update parent
    _executeParentUpdate(IMaster(msg.sender), _newParent);
  }

  /// @notice Get notified by parent that your sibling is removed
  /// @dev This contract will take the position of the parent
  /// @dev Only callable by current parent
  function siblingRemoved() external override onlyParent {
    // Get current parent of parent
    IMaster _newParent = parent.parent();

    // Take position of current parent
    _verifyParentUpdate(IMaster(msg.sender), _newParent);
    // NOTE: _verifyNewParent() is skipped on this call
    // As address(this) should be added as a child after the function returns
    _executeParentUpdate(IMaster(msg.sender), _newParent);
  }

  /// @notice Verify if `_newParent` is able to be our new parent
  /// @param _newParent Address of the new parent
  /// @return otherChild Address of the child that isn't address(this)
  function _verifyNewParent(IMaster _newParent) internal view returns (INode otherChild) {
    // The setup needs to be completed of parent
    if (_newParent.setupCompleted() == false) revert SetupNotCompleted(_newParent);

    // get first child
    INode firstChild = _newParent.childOne();
    INode secondChild;

    // is address(this) childOne?
    bool isFirstChild = address(firstChild) == address(this);
    bool isSecondChild = false;

    // Parent only has a childTwo if it isn't master
    if (!_newParent.isMaster()) {
      // get second child
      secondChild = ISplitter(address(_newParent)).childTwo();
      // is address(this) childTwo?
      isSecondChild = address(secondChild) == address(this);
    }

    // Check if address(this) is referenced as both childs
    if (isFirstChild && isSecondChild) revert BothChild();
    // Check if address(this) isn't referenced at all
    if (!isFirstChild && !isSecondChild) revert NotChild();

    // return child that isn't address(this)
    if (isFirstChild) {
      return secondChild;
    }
    return firstChild;
  }

  /// @notice Verify if `_newParent` can replace `_currentParent`
  /// @param _currentParent Address of our current `parent`
  /// @param _newParent Address of our future `parent`
  function _verifyParentUpdate(IMaster _currentParent, IMaster _newParent) internal view {
    // Revert if it's the same address
    if (address(_newParent) == address(this)) revert InvalidParentAddress();
    // Revert if the address is parent
    if (address(_newParent) == address(_currentParent)) revert InvalidParentAddress();
    // Revert if core is invalid
    if (_currentParent.core() != _newParent.core()) revert InvalidCore();
    // Revert if want is invalid
    if (_currentParent.want() != _newParent.want()) revert InvalidWant();
  }

  /// @notice Set parent in storage
  /// @param _currentParent Address of our current `parent`
  /// @param _newParent Address of our future `parent`
  function _executeParentUpdate(IMaster _currentParent, IMaster _newParent) internal {
    // Make `_newParent` our new parent
    parent = _newParent;
    emit ParentUpdate(_currentParent, _newParent);
  }

  /// @notice Replace address(this) with `_newNode`
  function _replace(INode _newNode) internal {
    if (address(_newNode) == address(0)) revert ZeroArg();
    if (_newNode.setupCompleted() == false) revert SetupNotCompleted(_newNode);
    if (address(_newNode) == address(this)) revert InvalidArg();
    if (_newNode.parent() != parent) revert InvalidParent();
    if (_newNode.core() != core) revert InvalidCore();
    if (_newNode.want() != want) revert InvalidWant();

    // Make sure our parent references `_newNode` as it's child
    parent.updateChild(_newNode);

    emit Replace(_newNode);
    emit Obsolete(INode(address(this)));
  }

  /*//////////////////////////////////////////////////////////////
                        YIELD STRATEGY LOGIC
  //////////////////////////////////////////////////////////////*/

  function balanceOf() external view override returns (uint256 amount) {
    return _balanceOf();
  }

  function withdrawAll() external override onlyParent returns (uint256 amount) {
    amount = _withdrawAll();
  }

  function withdrawAllByAdmin() external override onlyOwner returns (uint256 amount) {
    amount = _withdrawAll();
    emit AdminWithdraw(amount);
  }

  function withdraw(uint256 _amount) external override onlyParent {
    if (_amount == 0) revert ZeroArg();

    _withdraw(_amount);
  }

  function withdrawByAdmin(uint256 _amount) external override onlyOwner {
    if (_amount == 0) revert ZeroArg();

    _withdraw(_amount);
    emit AdminWithdraw(_amount);
  }

  function deposit() external override onlyParent {
    _deposit();
  }

  function _balanceOf() internal view virtual returns (uint256 amount) {}

  function _withdrawAll() internal virtual returns (uint256 amount) {}

  function _withdraw(uint256 _amount) internal virtual {}

  function _deposit() internal virtual {}
}