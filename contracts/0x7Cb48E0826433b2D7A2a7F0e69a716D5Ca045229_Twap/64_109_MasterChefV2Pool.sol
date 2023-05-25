// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "@openzeppelin/contracts/math/SafeMath.sol";

import "../interfaces/IMasterChefRewarder.sol";

import "../BasePool.sol";

// !!!! WIP !!!!!
// This code doesn't work. You can deposit via sushi, withdraw through normal functions.
// Must separate the balances and only keep them the same for the rewards.

/**
 * Provides adapters to allow this reward contract to be used as a MASTERCHEF V2 Rewards contract
 */
abstract contract MasterChefV2Pool is BasePool, IMasterChefRewarder {
  using SafeMath for uint256;

  address private immutable masterchefV2;

  /* ========== CONSTRUCTOR ========== */

  /**
   * @notice Construct a new MasterChefV2Pool
   * @param _admin The default role controller
   * @param _rewardDistribution The reward distributor (can change reward rate)
   * @param _rewardToken The reward token to distribute
   * @param _stakingToken The staking token used to qualify for rewards
   * @param _duration The duration for each reward distribution
   * @param _masterchefv2 The trusted masterchef contract
   */
  constructor(
    address _admin,
    address _rewardDistribution,
    address _rewardToken,
    address _stakingToken,
    uint256 _duration,
    address _masterchefv2
  )
    BasePool(
      _admin,
      _rewardDistribution,
      _rewardToken,
      _stakingToken,
      _duration
    )
  {
    masterchefV2 = _masterchefv2;
  }

  /* ========== MODIFIERS ========== */

  modifier onlyMCV2 {
    require(msg.sender == masterchefV2, "MasterChefV2Pool/OnlyMCV2");
    _;
  }

  /* ========== VIEWS ========== */

  function pendingTokens(
    uint256,
    address user,
    uint256
  )
    external
    view
    override(IMasterChefRewarder)
    returns (IERC20[] memory rewardTokens, uint256[] memory rewardAmounts)
  {
    IERC20[] memory _rewardTokens = new IERC20[](1);
    _rewardTokens[0] = (rewardToken);
    uint256[] memory _rewardAmounts = new uint256[](1);
    _rewardAmounts[0] = earned(user);
    return (_rewardTokens, _rewardAmounts);
  }

  /* ========== MUTATIVE FUNCTIONS ========== */

  /**
   * Adds to the internal balance record,
   */
  function onSushiReward(
    uint256,
    address _user,
    address,
    uint256,
    uint256 newLpAmount
  ) external override(IMasterChefRewarder) onlyMCV2 updateReward(_user) {
    uint256 internalBalance = _balances[_user];
    if (internalBalance > newLpAmount) {
      // _withdrawWithoutPush(_user, internalBalance.sub(newLpAmount));
    } else if (internalBalance < newLpAmount) {
      // _stakeWithoutPull(_user, _user, newLpAmount.sub(internalBalance));
    }
  }
}