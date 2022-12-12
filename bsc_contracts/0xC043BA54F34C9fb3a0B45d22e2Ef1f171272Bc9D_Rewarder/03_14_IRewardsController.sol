// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;
pragma experimental ABIEncoderV2;

import {IRewardsDistributor} from './IRewardsDistributor.sol';
import {DistributionTypes} from '../libraries/DistributionTypes.sol';

interface IRewardsController is IRewardsDistributor {
  event RewardsClaimed(
    address indexed user,
    address indexed reward,    
    address indexed to,
    address claimer,
    uint256 amount
  );

  event ClaimerSet(address indexed user, address indexed claimer);

  function setClaimer(address user, address claimer) external;

  function getClaimer(address user) external view returns (address);

  function configureAssets(DistributionTypes.RewardsConfigInput[] memory config) external;

  function handleAction(
    address asset,
    uint256 userBalance,
    uint256 totalSupply
  ) external;

  function claimRewards(
    address[] calldata assets,
    uint256 amount,
    address to,
    address reward
  ) external returns (uint256);

  function claimRewardsOnBehalf(
    address[] calldata assets,
    uint256 amount,
    address user,
    address to,
    address reward
  ) external returns (uint256);


  function claimRewardsToSelf(
    address[] calldata assets,
    uint256 amount,
    address reward
  ) external returns (uint256);

  function claimAllRewards(address[] calldata assets, address to)
    external
    returns (address[] memory rewardsList, uint256[] memory claimedAmounts);

  function claimAllRewardsOnBehalf(
    address[] calldata assets,
    address user,
    address to
  ) external returns (address[] memory rewardsList, uint256[] memory claimedAmounts);

  function claimAllRewardsToSelf(address[] calldata assets)
    external
    returns (address[] memory rewardsList, uint256[] memory claimedAmounts);
}