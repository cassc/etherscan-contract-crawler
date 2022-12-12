// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;
pragma experimental ABIEncoderV2;

import {IRewardsController} from './interfaces/IRewardsController.sol';
import {RewardsDistributor} from './RewardsDistributor.sol';
import {IScaledBalanceToken} from './interfaces/IScaledBalanceToken.sol';
import {DistributionTypes} from './libraries/DistributionTypes.sol';

abstract contract RewardsController is RewardsDistributor, IRewardsController {
	// user => authorized claimer
	mapping(address => address) internal _authorizedClaimers;

  modifier onlyAuthorizedClaimers(address claimer, address user) {
    require(_authorizedClaimers[user] == claimer, 'CLAIMER_UNAUTHORIZED');
    _;
  }

  function getClaimer(address user) external view override returns (address) {
    return _authorizedClaimers[user];
  }

  function setClaimer(address user, address caller) external override onlyOwner {
    _authorizedClaimers[user] = caller;
    emit ClaimerSet(user, caller);
  }

  function configureAssets(DistributionTypes.RewardsConfigInput[] memory config)
    external
    override
    onlyOwner
  {
    for (uint256 i = 0; i < config.length; i++) {
      config[i].totalSupply = IScaledBalanceToken(config[i].asset).scaledTotalSupply();
    }
    _configureAssets(config);
  }

  function handleAction(
    address user,
    uint256 totalSupply,
    uint256 userBalance
  ) external override {
    _updateUserRewardsPerAssetInternal(msg.sender, user, userBalance, totalSupply);
  }

	function claimRewards(
    address[] calldata assets,
    uint256 amount,
    address to,
    address reward
  ) external override returns (uint256) {
    require(to != address(0), 'INVALID_TO_ADDRESS');
    return _claimRewards(assets, amount, msg.sender, msg.sender, to, reward);
  }

  function claimRewardsOnBehalf(
    address[] calldata assets,
    uint256 amount,
    address user,
    address to,
    address reward
  ) external override onlyAuthorizedClaimers(msg.sender, user) returns (uint256) {
    require(user != address(0), 'INVALID_USER_ADDRESS');
    require(to != address(0), 'INVALID_TO_ADDRESS');
    return _claimRewards(assets, amount, msg.sender, user, to, reward);
  }

  function claimRewardsToSelf(
    address[] calldata assets,
    uint256 amount,
    address reward
  ) external override returns (uint256) {
    return _claimRewards(assets, amount, msg.sender, msg.sender, msg.sender, reward);
  }

  function claimAllRewards(address[] calldata assets, address to)
    external
    override
    returns (address[] memory rewardTokens, uint256[] memory claimedAmounts)
  {
    require(to != address(0), 'INVALID_TO_ADDRESS');
    return _claimAllRewards(assets, msg.sender, msg.sender, to);
  }

  function claimAllRewardsOnBehalf(
    address[] calldata assets,
    address user,
    address to
  )
    external
    override
    onlyAuthorizedClaimers(msg.sender, user)
    returns (address[] memory rewardTokens, uint256[] memory claimedAmounts)
  {
    require(user != address(0), 'INVALID_USER_ADDRESS');
    require(to != address(0), 'INVALID_TO_ADDRESS');
    return _claimAllRewards(assets, msg.sender, user, to);
  }

  function claimAllRewardsToSelf(address[] calldata assets)
    external
    override
    returns (address[] memory rewardTokens, uint256[] memory claimedAmounts)
  {
    return _claimAllRewards(assets, msg.sender, msg.sender, msg.sender);
  }

  function _getUserStake(address[] calldata assets, address user)
    internal
    view
    override
    returns (DistributionTypes.UserAssetInput[] memory userState)
  {
    userState = new DistributionTypes.UserAssetInput[](assets.length);
    for (uint256 i = 0; i < assets.length; i++) {
      userState[i].underlyingAsset = assets[i];
      (userState[i].userBalance, userState[i].totalSupply) = IScaledBalanceToken(assets[i])
        .getScaledUserBalanceAndSupply(user);
    }
    return userState;
  }

  function _claimRewards(
    address[] calldata assets,
    uint256 amount,
    address claimer,
    address user,
    address to,
    address reward
  ) internal returns (uint256) {
    if (amount == 0) {
      return 0;
    }
    uint256 unclaimedRewards = _usersUnclaimedRewards[user][reward];

    if (amount > unclaimedRewards) {
      _distributeRewards(user, _getUserStake(assets, user));
      unclaimedRewards = _usersUnclaimedRewards[user][reward];
    }

    if (unclaimedRewards == 0) {
      return 0;
    }

    uint256 amountToClaim = amount > unclaimedRewards ? unclaimedRewards : amount;
    _usersUnclaimedRewards[user][reward] = unclaimedRewards - amountToClaim; // Safe due to the previous line

    _transferRewards(to, reward, amountToClaim);
    emit RewardsClaimed(user, reward, to, claimer, amountToClaim);

    return amountToClaim;
  }

  function _claimAllRewards(
    address[] calldata assets,
    address claimer,
    address user,
    address to
  ) internal returns (address[] memory rewardTokens, uint256[] memory claimedAmounts) {
    _distributeRewards(user, _getUserStake(assets, user));

    rewardTokens = new address[](_rewardTokens.length);
    claimedAmounts = new uint256[](_rewardTokens.length);

    for (uint256 i = 0; i < _rewardTokens.length; i++) {
      address reward = _rewardTokens[i];
      uint256 rewardAmount = _usersUnclaimedRewards[user][reward];

      rewardTokens[i] = reward;
      claimedAmounts[i] = rewardAmount;

      if (rewardAmount != 0) {
        _usersUnclaimedRewards[user][reward] = 0;
        _transferRewards(to, reward, rewardAmount);
        emit RewardsClaimed(user, reward, to, claimer, rewardAmount);
      }
    }
    return (rewardTokens, claimedAmounts);
  }

  function _transferRewards(
    address to,
    address reward,
    uint256 amount
  ) internal {
    bool success = transferRewards(to, reward, amount);
    require(success == true, 'TRANSFER_ERROR');
  }

  function transferRewards(address to, address reward, uint256 amount) internal virtual returns (bool);
}