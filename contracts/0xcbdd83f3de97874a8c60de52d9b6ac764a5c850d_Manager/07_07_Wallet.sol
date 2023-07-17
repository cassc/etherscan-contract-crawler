// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0;

/// Wraps the functionality of a Federation base wallet
interface Wallet {
  error NotEnabled();
  error ModuleAlreadyInitialized();
  error TransactionReverted();
  error LockDurationRequestTooLong();
  error LockActive();

  event SetModule(address indexed module, bool enabled);

  event ExecuteTransaction(address indexed caller, address indexed target, uint256 value);

  event Received(uint256 indexed value, address indexed sender, bytes data);

  event RequestLock(address indexed module, uint256 duration);

  event ReleaseLock(address indexed module);

  event MaxLockDurationBlocksChanged(uint256 blocks);

  function initialize(address) external;

  function execute(address, uint256, bytes calldata) external returns (bytes memory);

  function setModule(address, bool) external;

  function moduleEnabled(address) external view returns (bool);

  function requestLock(uint256) external returns (uint256);

  function releaseLock() external;

  function hasActiveLock() external view returns (bool);

  function setMaxLockDurationBlocks(uint256 _blocks) external;

  function maxLockDurationBlocks() external view returns (uint256);
}