// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

import {SafeERC20} from '../dependencies/openzeppelin/contracts/SafeERC20.sol';
import {VersionedInitializable} from '../protocol/libraries/sturdy-upgradeability/VersionedInitializable.sol';
import {IERC20} from '../dependencies/openzeppelin/contracts/IERC20.sol';
import {IScaledBalanceToken} from '../interfaces/IScaledBalanceToken.sol';
import {ILendingPoolAddressesProvider} from '../interfaces/ILendingPoolAddressesProvider.sol';
import {UserData, AssetData, AggregatedRewardsData} from '../interfaces/IVariableYieldDistribution.sol';
import {IncentiveVault} from '../protocol/vault/IncentiveVault.sol';
import {Errors} from '../protocol/libraries/helpers/Errors.sol';
import {Math} from '../dependencies/openzeppelin/contracts/Math.sol';

/**
 * @title VariableYieldDistribution
 * @notice Distributor contract that sends some rewards to borrowers who provide some special tokens such as Curve LP tokens.
 * @author Sturdy
 **/
contract VariableYieldDistribution is VersionedInitializable {
  using SafeERC20 for IERC20;

  uint256 private constant REVISION = 4;
  uint8 private constant PRECISION = 27;
  address public immutable EMISSION_MANAGER;

  ILendingPoolAddressesProvider internal _addressProvider;

  mapping(address => AssetData) public assets;

  event AssetRegistered(address indexed asset, address indexed yieldAddress);
  event AssetIndexUpdated(address indexed asset, uint256 index, uint256 rewardsAmount);
  event UserIndexUpdated(
    address indexed user,
    address indexed asset,
    uint256 index,
    uint256 expectedRewardsAmount
  );
  event RewardsReceived(address indexed asset, address indexed rewardToken, uint256 receivedAmount);
  event RewardsAccrued(address indexed user, address indexed asset, uint256 amount);
  event RewardsClaimed(
    address indexed asset,
    address indexed user,
    address indexed to,
    uint256 amount
  );

  modifier onlyEmissionManager() {
    require(msg.sender == EMISSION_MANAGER, Errors.CALLER_NOT_EMISSION_MANAGER);
    _;
  }

  modifier onlyIncentiveController() {
    require(
      msg.sender == _addressProvider.getIncentiveController(),
      Errors.CALLER_NOT_INCENTIVE_CONTROLLER
    );
    _;
  }

  constructor(address emissionManager) {
    EMISSION_MANAGER = emissionManager;
  }

  /**
   * @dev Initialize IStakedTokenIncentivesController
   * @param _provider the address of the corresponding addresses provider
   **/
  function initialize(ILendingPoolAddressesProvider _provider) external initializer {
    _addressProvider = _provider;
  }

  /**
   * @dev Register an asset with vault which will keep some of yield for borrowers
   * @param asset The address of the reference asset
   * @param yieldAddress The address of the vault
   */
  function registerAsset(address asset, address yieldAddress) external payable onlyEmissionManager {
    AssetData storage assetData = assets[asset];
    address rewardToken = IncentiveVault(yieldAddress).getIncentiveToken();

    require(assetData.yieldAddress == address(0), Errors.YD_VR_ASSET_ALREADY_IN_USE);
    require(rewardToken != address(0), Errors.YD_VR_INVALID_VAULT);

    uint256 totalStaked = IScaledBalanceToken(asset).scaledTotalSupply();
    assetData.yieldAddress = yieldAddress;
    assetData.rewardToken = rewardToken;

    (uint256 lastAvailableRewards, uint256 increasedRewards) = _getAvailableRewardsAmount(
      assetData
    );

    _updateAssetStateInternal(
      asset,
      assetData,
      totalStaked,
      lastAvailableRewards,
      increasedRewards
    );

    emit AssetRegistered(asset, yieldAddress);
  }

  function receivedRewards(
    address asset,
    address rewardToken,
    uint256 amount
  ) external {
    AssetData storage assetData = assets[asset];
    address _rewardToken = assetData.rewardToken;
    address _yieldAddress = assetData.yieldAddress;
    uint256 lastAvailableRewards = assetData.lastAvailableRewards;

    require(msg.sender == _yieldAddress, Errors.YD_VR_CALLER_NOT_VAULT);
    require(_rewardToken != address(0), Errors.YD_VR_ASSET_NOT_REGISTERED);
    require(rewardToken == _rewardToken, Errors.YD_VR_REWARD_TOKEN_NOT_VALID);
    require(amount >= lastAvailableRewards, Errors.YD_VR_INVALID_REWARDS_AMOUNT);

    uint256 increasedRewards = amount - lastAvailableRewards;
    uint256 totalStaked = IScaledBalanceToken(asset).scaledTotalSupply();

    _updateAssetStateInternal(asset, assetData, totalStaked, 0, increasedRewards);

    emit RewardsReceived(asset, rewardToken, amount);
  }

  function handleAction(
    address user,
    address asset,
    uint256 totalSupply,
    uint256 userBalance
  ) external payable onlyIncentiveController {
    uint256 accruedRewards = _updateUserAssetInternal(user, asset, userBalance, totalSupply);
    if (accruedRewards != 0) {
      emit RewardsAccrued(user, asset, accruedRewards);
    }
  }

  function getRewardsBalance(address[] calldata _assets, address _user)
    external
    view
    returns (AggregatedRewardsData[] memory)
  {
    uint256 length = _assets.length;
    AggregatedRewardsData[] memory rewards = new AggregatedRewardsData[](length);

    for (uint256 i; i < length; ++i) {
      (uint256 stakedByUser, ) = IScaledBalanceToken(_assets[i]).getScaledUserBalanceAndSupply(
        _user
      );
      rewards[i].asset = _assets[i];
      (rewards[i].rewardToken, rewards[i].balance) = _getUnclaimedRewards(
        _user,
        _assets[i],
        stakedByUser
      );
    }

    return rewards;
  }

  function claimRewards(
    address[] calldata _assets,
    uint256[] calldata _amounts,
    address _to
  ) external returns (uint256) {
    require(_to != address(0), 'INVALID_TO_ADDRESS');
    require(_assets.length == _amounts.length, Errors.YD_VR_INVALID_REWARDS_AMOUNT);

    uint256 claimedAmount;
    for (uint256 i; i < _assets.length; ++i) {
      claimedAmount += _claimRewards(_assets[i], _amounts[i], msg.sender, _to);
    }

    return claimedAmount;
  }

  function getUserAssetData(address user, address asset)
    public
    view
    returns (
      uint256,
      uint256,
      uint256
    )
  {
    UserData storage userData = assets[asset].users[user];
    return (userData.index, userData.expectedRewards, userData.claimableRewards);
  }

  function getAssetData(address asset)
    public
    view
    returns (
      uint256,
      address,
      address,
      uint256
    )
  {
    return (
      assets[asset].index,
      assets[asset].yieldAddress,
      assets[asset].rewardToken,
      assets[asset].lastAvailableRewards
    );
  }

  /**
   * @dev returns the revision of the implementation contract
   */
  function getRevision() internal pure override returns (uint256) {
    return REVISION;
  }

  /**
   * @dev Claims reward for an user on behalf, on all the assets of the lending pool, accumulating the pending rewards.
   * @param amount Amount of rewards to claim
   * @param user Address to check and claim rewards
   * @param to Address that will be receiving the rewards
   * @return Rewards claimed
   **/
  function _claimRewards(
    address asset,
    uint256 amount,
    address user,
    address to
  ) internal returns (uint256) {
    if (amount == 0) {
      return 0;
    }

    AssetData storage assetData = assets[asset];
    UserData storage userData = assetData.users[user];
    address rewardToken = assetData.rewardToken;

    (uint256 stakedByUser, uint256 totalStaked) = IScaledBalanceToken(asset)
      .getScaledUserBalanceAndSupply(user);

    _updateUserAssetInternal(user, asset, stakedByUser, totalStaked);

    uint256 unclaimedRewards = userData.claimableRewards;
    if (unclaimedRewards == 0) {
      return 0;
    }

    uint256 amountToClaim = amount > unclaimedRewards ? unclaimedRewards : amount;

    IERC20 stakeToken = IERC20(rewardToken);
    if (stakeToken.balanceOf(address(this)) >= amountToClaim) {
      stakeToken.safeTransfer(to, amountToClaim);
      userData.claimableRewards = unclaimedRewards - amountToClaim;
      emit RewardsClaimed(asset, user, to, amountToClaim);
    }

    return amountToClaim;
  }

  /**
   * @dev Updates the state of one distribution, mainly rewards index and timestamp
   * @param asset The address of the asset being updated
   * @param assetData Storage pointer to the distribution's config
   * @param totalStaked Current total of staked assets for this distribution
   * @return The new distribution index
   **/
  function _updateAssetStateInternal(
    address asset,
    AssetData storage assetData,
    uint256 totalStaked,
    uint256 lastAvailableRewards,
    uint256 increasedRewards
  ) internal returns (uint256) {
    uint256 oldIndex = assetData.index;
    uint256 oldAvailableRewards = assetData.lastAvailableRewards;

    uint256 newIndex = _getAssetIndex(oldIndex, increasedRewards, totalStaked);

    if (newIndex != oldIndex || lastAvailableRewards != oldAvailableRewards) {
      assetData.index = newIndex;
      assetData.lastAvailableRewards = lastAvailableRewards;
      if (lastAvailableRewards == 0) assetData.claimableIndex = newIndex;
      emit AssetIndexUpdated(asset, newIndex, lastAvailableRewards);
    }

    return newIndex;
  }

  /**
   * @dev Updates the state of an user in a distribution
   * @param user The user's address
   * @param asset The address of the reference asset of the distribution
   * @param stakedByUser Amount of tokens staked by the user in the distribution at the moment
   * @param totalStaked Total tokens staked in the distribution
   * @return The accrued rewards for the user until the moment
   **/
  function _updateUserAssetInternal(
    address user,
    address asset,
    uint256 stakedByUser,
    uint256 totalStaked
  ) internal returns (uint256) {
    AssetData storage assetData = assets[asset];
    UserData storage userData = assetData.users[user];
    uint256 userIndex = userData.index;
    uint256 claimableIndex = assetData.claimableIndex;
    uint256 expectedRewards = userData.expectedRewards;
    uint256 claimableRewards = userData.claimableRewards;
    uint256 accruedRewards;

    (uint256 lastAvailableRewards, uint256 increasedRewards) = _getAvailableRewardsAmount(
      assetData
    );
    uint256 newIndex = _updateAssetStateInternal(
      asset,
      assetData,
      totalStaked,
      lastAvailableRewards,
      increasedRewards
    );

    if (userIndex == newIndex) return accruedRewards;

    if (claimableIndex >= userIndex) {
      claimableRewards += expectedRewards;
      expectedRewards = 0;
    }

    if (stakedByUser != 0) {
      if (claimableIndex >= userIndex) {
        claimableRewards += _getRewards(stakedByUser, claimableIndex, userIndex);
        accruedRewards = _getRewards(stakedByUser, newIndex, claimableIndex);
      } else {
        accruedRewards = _getRewards(stakedByUser, newIndex, userIndex);
      }
      expectedRewards += accruedRewards;
    }

    userData.index = newIndex;
    if (userData.expectedRewards != expectedRewards) userData.expectedRewards = expectedRewards;
    if (userData.claimableRewards != claimableRewards) userData.claimableRewards = claimableRewards;
    emit UserIndexUpdated(user, asset, newIndex, expectedRewards);

    return accruedRewards;
  }

  /**
   * @dev Return the accrued rewards for an user over a list of distribution
   * @param user The address of the user
   * @param asset The address of the asset
   * @param stakedByUser The balance of the user of the asset
   * @return rewardToken The address of the reward token
   * @return unclaimedRewards The accrued rewards for the user until the moment
   **/
  function _getUnclaimedRewards(
    address user,
    address asset,
    uint256 stakedByUser
  ) internal view returns (address rewardToken, uint256 unclaimedRewards) {
    AssetData storage assetData = assets[asset];
    rewardToken = assetData.rewardToken;
    uint256 claimableIndex = assetData.claimableIndex;

    UserData storage userData = assetData.users[user];
    uint256 userIndex = userData.index;
    unclaimedRewards = userData.claimableRewards;

    if (claimableIndex >= userIndex) {
      unclaimedRewards += userData.expectedRewards;
      if (stakedByUser != 0) {
        unclaimedRewards += _getRewards(stakedByUser, claimableIndex, userIndex);
      }
    }
  }

  /**
   * @dev Internal function for the calculation of user's rewards on a distribution
   * @param principalUserBalance Amount staked by the user on a distribution
   * @param reserveIndex Current index of the distribution
   * @param userIndex Index stored for the user, representation his staking moment
   * @return The rewards
   **/
  function _getRewards(
    uint256 principalUserBalance,
    uint256 reserveIndex,
    uint256 userIndex
  ) internal pure returns (uint256) {
    return (principalUserBalance * (reserveIndex - userIndex)) / 10**uint256(PRECISION);
  }

  /**
   * @dev Calculates the next value of an specific distribution index, with validations
   * @param currentIndex Current index of the distribution
   * @param increasedRewards Earned Amount
   * @param totalBalance of tokens considered for the distribution
   * @return The new index.
   **/
  function _getAssetIndex(
    uint256 currentIndex,
    uint256 increasedRewards,
    uint256 totalBalance
  ) internal pure returns (uint256) {
    if (increasedRewards == 0 || totalBalance == 0) {
      return currentIndex;
    }

    return (increasedRewards * (10**uint256(PRECISION))) / totalBalance + currentIndex;
  }

  function _getAvailableRewardsAmount(AssetData storage assetData)
    internal
    view
    returns (uint256 lastAvailableRewards, uint256 increasedRewards)
  {
    address vault = assetData.yieldAddress;
    uint256 oldAmount = assetData.lastAvailableRewards;
    lastAvailableRewards = IncentiveVault(vault).getCurrentTotalIncentiveAmount();
    require(lastAvailableRewards >= oldAmount, Errors.YD_VR_INVALID_REWARDS_AMOUNT);
    increasedRewards = lastAvailableRewards - oldAmount;
  }
}