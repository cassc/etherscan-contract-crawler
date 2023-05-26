// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

interface IXfaiFactory {
  function getPool(address _token) external view returns (address pool);

  function allPools(uint256) external view returns (address pool);

  function poolCodeHash() external pure returns (bytes32);

  function allPoolsLength() external view returns (uint);

  function createPool(address _token) external returns (address pool);

  function setXfaiCore(address _core) external;

  function getXfaiCore() external view returns (address);

  function setOwner(address _owner) external;

  function getOwner() external view returns (address);

  event ChangedOwner(address indexed owner);
  event ChangedCore(address indexed core);
  event Whitelisting(bool state);
  event PoolCreated(address indexed token, address indexed pool, uint allPoolsSize);
}