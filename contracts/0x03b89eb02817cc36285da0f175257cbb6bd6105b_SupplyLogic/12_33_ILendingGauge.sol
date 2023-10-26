// SPDX-License-Identifier: LGPL-3.0

pragma solidity 0.8.17;

import './ILT.sol';
import './IGaugeController.sol';
import './IVotingEscrow.sol';
import './IMinter.sol';
import '../protocol/libraries/types/DataTypes.sol';

interface ILendingGauge {
  /**
   * @dev Emitted when LendingGauge is created.
   * @param addressesProvider The address of the registered PoolAddressesProvider
   * @param assset The address of the underlying asset of the reserve
   * @param _phases Utilization rate and allocation ratio parameter configuration
   */
  event AddPhases(address indexed addressesProvider, address indexed assset, DataTypes.Phase[] _phases);

  function initialize(
    address _pool,
    address _minter,
    address _votingEscrow,
    address _underlyingAsset
  ) external;

  function votingEscrow() external view returns (IVotingEscrow);

  function controller() external view returns (IGaugeController);

  function minter() external view returns (IMinter);

  function updateAllocation() external returns (bool);

  function isKilled() external returns (bool);

  function hvCheckpoint(address _addr) external;

  function hvUpdateLiquidityLimit(address _addr) external;
}