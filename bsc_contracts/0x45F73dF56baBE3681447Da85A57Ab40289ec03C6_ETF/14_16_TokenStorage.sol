// SPDX-License-Identifier: MIT

pragma solidity 0.5.16;

import "../openzeppelin/SafeMath.sol";

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
   * @notice NFT contract that decides transfer limits for this token
   */
  address public NFT;

  /**
   * @notice Governor for this contract
   */
  address public gov;

  /**
   * @notice Pending governance for this contract
   */
  address public pendingGov;

  /**
   * @notice Approved rebaser for this contract
   */
  address public rebaser;

  /**
   * @notice Approved token guardian for this contract
   */
  address public guardian;

  /**
   * @notice Total supply of ETF
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
   * @notice Internal decimals used to handle scaling factor
   */
  uint256 public constant internalDecimals = 10 ** 24;

  /**
   * @notice Used for percentage maths
   */
  uint256 public constant BASE = 10 ** 18;

  /**
   * @notice Scaling factor that adjusts everyone's balances
   */
  uint256 public etfsScalingFactor;

  mapping(address => uint256) internal _etfBalances;

  mapping(address => mapping(address => uint256)) internal _allowedFragments;

  /**
   * @notice Used for storing 24hr transfer data of users
   */
  mapping(address => uint256) public lastTransferTime;

  mapping(address => uint256) public totalTrackedTransfer;

  mapping(address => uint256) public balanceDuringCheckpoint;

  /**
   * @notice Initial supply
   */
  uint256 public initSupply;

  address public router;

  address public factory;

  address public dexPair;
}