// SPDX-License-Identifier: MIT
pragma solidity 0.5.16;

import "../../openzeppelin/SafeMath.sol";

contract TokenStorage {
  using SafeMath for uint256;

  /**
   * @notice EIP-20 token name for this token
   */
  string public name;

  /**
   * @notice EIP-20 token symbol for this token
   */
  string public symbol;

  /**
   * @notice EIP-20 token decimals for this token
   */
  uint8 public decimals;

  /**
   * @notice Governor for this contract
   */
  address public gov;

  /**
   * @notice Pending governance for this contract
   */
  address public pendingGov;

  /**
   * @notice Approved token emitter for this contract
   */
  address public emission;

  /**
   * @notice Approved token guardian for this contract
   */
  address public guardian;

  /**
   * @notice Total supply of SRVN
   */
  uint256 public totalSupply;

  /**
   * @notice Used for pausing and unpausing
   */
  bool internal _paused = false;

  /**
   * @notice Used for checking validity of Guardian
   */
  uint256 public guardianExpiration = block.timestamp.add(78 weeks); // Guardian expires in 1.5 years

  /**
   * @notice used for tracking freeze timestamp
   */
  mapping(address => uint256) internal lastFrozen;

  uint256 public freezeDelay = 14 days; // Delay between freezing the same target multiple times to avoid abuse

  /**
   * @notice Used for balance of the users and allowances
   */
  mapping(address => uint256) internal _balances;

  mapping(address => mapping(address => uint256)) internal _allowedBalances;

  bool public initialized = false;

  uint256 public currentSupply;
}