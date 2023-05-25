// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';
import '../../interfaces/peripherals/IKeep3rAccountance.sol';

abstract contract Keep3rAccountance is IKeep3rAccountance {
  using EnumerableSet for EnumerableSet.AddressSet;

  /// @notice List of all enabled keepers
  EnumerableSet.AddressSet internal _keepers;

  /// @inheritdoc IKeep3rAccountance
  mapping(address => uint256) public override workCompleted;

  /// @inheritdoc IKeep3rAccountance
  mapping(address => uint256) public override firstSeen;

  /// @inheritdoc IKeep3rAccountance
  mapping(address => bool) public override disputes;

  /// @inheritdoc IKeep3rAccountance
  /// @notice Mapping (job => bonding => amount)
  mapping(address => mapping(address => uint256)) public override bonds;

  /// @inheritdoc IKeep3rAccountance
  mapping(address => mapping(address => uint256)) public override jobTokenCredits;

  /// @notice The current liquidity credits available for a job
  mapping(address => uint256) internal _jobLiquidityCredits;

  /// @notice Map the address of a job to its correspondent periodCredits
  mapping(address => uint256) internal _jobPeriodCredits;

  /// @notice Enumerable array of Job Tokens for Credits
  mapping(address => EnumerableSet.AddressSet) internal _jobTokens;

  /// @notice List of liquidities that a job has (job => liquidities)
  mapping(address => EnumerableSet.AddressSet) internal _jobLiquidities;

  /// @notice Liquidity pool to observe
  mapping(address => address) internal _liquidityPool;

  /// @notice Tracks if a pool has KP3R as token0
  mapping(address => bool) internal _isKP3RToken0;

  /// @inheritdoc IKeep3rAccountance
  mapping(address => mapping(address => uint256)) public override pendingBonds;

  /// @inheritdoc IKeep3rAccountance
  mapping(address => mapping(address => uint256)) public override canActivateAfter;

  /// @inheritdoc IKeep3rAccountance
  mapping(address => mapping(address => uint256)) public override canWithdrawAfter;

  /// @inheritdoc IKeep3rAccountance
  mapping(address => mapping(address => uint256)) public override pendingUnbonds;

  /// @inheritdoc IKeep3rAccountance
  mapping(address => bool) public override hasBonded;

  /// @notice List of all enabled jobs
  EnumerableSet.AddressSet internal _jobs;

  /// @inheritdoc IKeep3rAccountance
  function jobs() external view override returns (address[] memory _list) {
    _list = _jobs.values();
  }

  /// @inheritdoc IKeep3rAccountance
  function keepers() external view override returns (address[] memory _list) {
    _list = _keepers.values();
  }
}