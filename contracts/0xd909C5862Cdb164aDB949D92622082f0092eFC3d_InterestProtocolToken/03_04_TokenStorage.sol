// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
pragma experimental ABIEncoderV2;

import "../../_external/Context.sol";

contract TokenDelegatorStorage is Context {
  /// @notice Active brains of Token
  address public implementation;

  /// @notice EIP-20 token name for this token
  string public name = "Interest Protocol";

  /// @notice EIP-20 token symbol for this token
  string public symbol = "IPT";

  /// @notice Total number of tokens in circulation
  uint256 public totalSupply;

  /// @notice EIP-20 token decimals for this token
  uint8 public constant decimals = 18;

  address public owner;
  /// @notice onlyOwner modifier checks if sender is owner
  modifier onlyOwner() {
    require(owner == _msgSender(), "onlyOwner: sender not owner");
    _;
  }
}

/**
 * @title Storage for Token Delegate
 * @notice For future upgrades, do not change TokenDelegateStorageV1. Create a new
 * contract which implements TokenDelegateStorageV1 and following the naming convention
 * TokenDelegateStorageVX.
 */
contract TokenDelegateStorageV1 is TokenDelegatorStorage {
  // Allowance amounts on behalf of others
  mapping(address => mapping(address => uint96)) internal allowances;

  // Official record of token balances for each account
  mapping(address => uint96) internal balances;

  /// @notice A record of each accounts delegate
  mapping(address => address) public delegates;

  /// @notice A checkpoint for marking number of votes from a given block
  struct Checkpoint {
    uint32 fromBlock;
    uint96 votes;
  }
  /// @notice A record of votes checkpoints for each account, by index
  mapping(address => mapping(uint32 => Checkpoint)) public checkpoints;

  /// @notice The number of checkpoints for each account
  mapping(address => uint32) public numCheckpoints;

  /// @notice A record of states for signing / validating signatures
  mapping(address => uint256) public nonces;
}