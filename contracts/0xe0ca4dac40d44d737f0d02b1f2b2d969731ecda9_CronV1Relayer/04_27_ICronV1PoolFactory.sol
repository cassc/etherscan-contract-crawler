// (c) Copyright 2022, Bad Pumpkin Inc. All Rights Reserved
//
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.7.6;

import { ICronV1Pool } from "../interfaces/ICronV1Pool.sol";

interface ICronV1PoolFactory {
  /// @notice This event tracks pool creations from this factory
  /// @param pool the address of the pool
  /// @param token0 The token 0 in this pool
  /// @param token1 The token 1 in this pool
  /// @param poolType The poolType set for this pool
  event CronV1PoolCreated(
    address indexed pool,
    address indexed token0,
    address indexed token1,
    ICronV1Pool.PoolType poolType
  );

  /// @notice This event tracks pool being set from this factory
  /// @param pool the address of the pool
  /// @param token0 The token 0 in this pool
  /// @param token1 The token 1 in this pool
  /// @param poolType The poolType set for this pool
  event CronV1PoolSet(
    address indexed pool,
    address indexed token0,
    address indexed token1,
    ICronV1Pool.PoolType poolType
  );

  /// @notice This event tracks pool deletions from this factory
  /// @param pool the address of the pool
  /// @param token0 The token 0 in this pool
  /// @param token1 The token 1 in this pool
  /// @param poolType The poolType set for this pool
  event CronV1PoolRemoved(
    address indexed pool,
    address indexed token0,
    address indexed token1,
    ICronV1Pool.PoolType poolType
  );

  /// @notice This event tracks pool creations from this factory
  /// @param oldAdmin the address of the previous admin
  /// @param newAdmin the address of the new admin
  event OwnerChanged(address indexed oldAdmin, address indexed newAdmin);

  // Functions
  function create(
    address _token0,
    address _token1,
    string memory _name,
    string memory _symbol,
    uint256 _poolType
  ) external returns (address);

  function set(
    address _token0,
    address _token1,
    uint256 _poolType,
    address _pool
  ) external;

  function remove(
    address _token0,
    address _token1,
    uint256 _poolType
  ) external;

  function transferOwnership(
    address _newOwner,
    bool _direct,
    bool _renounce
  ) external;

  function claimOwnership() external;

  function owner() external view returns (address);

  function pendingOwner() external view returns (address);

  function getPool(
    address _token0,
    address _token1,
    uint256 _poolType
  ) external view returns (address pool);
}