// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.17;

import {IPool} from './IPool.sol';
import {IPrime} from '../PrimeMembership/IPrime.sol';

/// @title Prime IPoolFactory interface
interface IPoolFactory {
  /// @notice Initialize the contract
  /// @dev This function is called only once during the contract deployment
  /// @param _prime Prime contract address
  /// @param _poolBeacon Beacon address for pool proxy pattern
  function __PoolFactory_init(address _prime, address _poolBeacon) external;

  /// @notice Creates a new pool
  /// @dev Callable only by prime members
  /// @param pooldata Bla bla bla
  /// @param members Pool members address encoded in bytes
  function createPool(IPool.PoolData calldata pooldata, bytes calldata members) external;

  function prime() external view returns (IPrime);
}