// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.19;

interface IDexfaiFactory {
  function getPool(address _token) external view returns (address pool);

  function allPools(uint256) external view returns (address pool);

  function poolCodeHash() external pure returns (bytes32);

  function allPoolsLength() external view returns (uint);

  function createPool(address _token) external returns (address pool);

  function setDexfaiCore(address _core) external;

  function getDexfaiCore() external view returns (address);

  function setOwner(address _owner) external;

  function setWhitelistingPhase(bool _state) external;

  function getOwner() external view returns (address);

  event ChangedOwner(address indexed owner);
  event ChangedCore(address indexed core);
  event Whitelisting(bool state);
  event PoolCreated(address indexed token, address indexed pool, uint allPoolsSize);
}