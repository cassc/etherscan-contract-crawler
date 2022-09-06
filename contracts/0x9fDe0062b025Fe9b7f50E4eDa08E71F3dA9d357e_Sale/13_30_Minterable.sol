// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../Error.sol";

contract Minterable is AccessControl, Ownable {
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

  // Minter address => allowed minting amount
  mapping(address => uint256) public minterAllowances;

  event LogMinterAdded(address indexed account);

  event LogMinterRemoved(address indexed account);

  event LogAllowanceIncreased(
    address indexed minter,
    uint256 amount
  );

  event LogAllowanceDecreased(
    address indexed minter,
    uint256 amount
  );

  /**
   * @dev Restricted to members of the `minter` role.
   */
  modifier onlyMinter() {
    if (!super.hasRole(MINTER_ROLE, msg.sender)) revert NoMinterRole();

    _;
  }

  /**
   * @dev Throw if `_account` is zero address or contract owner
   */
  modifier notZeroAndOwner(address _account) {
    if (_account == address(0) || _account == owner()) revert InvalidAddress();

    _;
  }

  /**
   * @dev Throw if `_amount` is zero
   */
  modifier notZero(uint256 _amount) {
    if (_amount == 0) revert InvalidAmount();

    _;
  }

  /**
   * @dev Contract owner is minter
   */
  constructor() {
    super._setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    super._setupRole(MINTER_ROLE, msg.sender);
  }

  /**
   * @dev Increase minting allowance
   *
   * Requirements:
   * - Only contract owner can call
   * @param _minter minter wallet; must not be zero nor owner address
   * @param _amount increasing allowance amount; must not be zero
   */
  function increaseAllowance(
    address _minter,
    uint256 _amount
  ) external onlyOwner notZeroAndOwner(_minter) notZero(_amount) {
    uint256 allowed = minterAllowances[_minter];
    if (allowed > type(uint256).max - _amount) revert MathOverflow();

    unchecked {
      // we will not overflow because of above check
      minterAllowances[_minter] = allowed + _amount;
      emit LogAllowanceIncreased(_minter, allowed + _amount);
    }
  }

  /**
   * @dev See {_decreaseAllowance}
   *
   * Requirements:
   * - Only contract owner can call
   */
  function decreaseAllowance(
    address _minter,
    uint256 _amount
  ) external onlyOwner {
    _decreaseAllowance(_minter, _amount);
  }

  /**
   * @dev Add a new minter
   *
   * Requirements:
   * - Only contract owner can call
   * @param _account minter address; must not be zero address; must not be minter
   */
  function addMinter(address _account) external onlyOwner {
    if (_account == address(0)) revert InvalidAddress();
    
    super._grantRole(MINTER_ROLE, _account);
    emit LogMinterAdded(_account);
  }

  /**
   * @dev Remove minter
   *
   * Requirements:
   * - Only contract owner can call
   * @param _account minter address; must be minter
   */
  function removeMinter(address _account) external onlyOwner {
    super._revokeRole(MINTER_ROLE, _account);
    emit LogMinterRemoved(_account);
  }

  /**
   * @dev Check minter role ownership
   * @param _account checking account
   */
  function isMinter(address _account) external view returns (bool) {
    return super.hasRole(MINTER_ROLE, _account);
  }  

  /**
   * @dev Override {Ownable-transferOwnership}
   * Super method has `onlyOwner` modifier
   * Revoke default admin role and minter role from old owner and grant to new owner
   * @param _newOwner new owner address; must not be zero address
   */
  function transferOwnership(address _newOwner) public virtual override {
    address oldOwner = owner();
    super._revokeRole(DEFAULT_ADMIN_ROLE, oldOwner);
    super._revokeRole(MINTER_ROLE, oldOwner);
    super._grantRole(DEFAULT_ADMIN_ROLE, _newOwner);
    super._grantRole(MINTER_ROLE, _newOwner);
    super.transferOwnership(_newOwner);
  }

  /**
   * @dev Decrease minting allowance
   * @param _minter minter wallet; must not be zero nor owner address
   * @param _amount increasing allowance amount; must not be zero; must not exceed current allowance
   */
  function _decreaseAllowance(
    address _minter,
    uint256 _amount
  ) internal notZeroAndOwner(_minter) notZero(_amount) {
    uint256 allowed = minterAllowances[_minter];
    if (_amount > allowed) revert ExceedMinterAllowance();

    unchecked {
      // we will not underflow because of above check
      minterAllowances[_minter] = allowed - _amount;
      emit LogAllowanceDecreased(_minter, allowed - _amount);
    }
  }
}