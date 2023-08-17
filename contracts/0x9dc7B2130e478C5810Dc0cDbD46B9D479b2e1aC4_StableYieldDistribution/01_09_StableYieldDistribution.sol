// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

import {SafeERC20} from '../dependencies/openzeppelin/contracts/SafeERC20.sol';
import {DistributionTypes} from '../lib/DistributionTypes.sol';
import {VersionedInitializable} from '../protocol/libraries/sturdy-upgradeability/VersionedInitializable.sol';
import {IERC20} from '../dependencies/openzeppelin/contracts/IERC20.sol';
import {IScaledBalanceToken} from '../interfaces/IScaledBalanceToken.sol';
import {ILendingPoolAddressesProvider} from '../interfaces/ILendingPoolAddressesProvider.sol';
import {Errors} from '../protocol/libraries/helpers/Errors.sol';

/**
 * @title StableYieldDistribution
 * @notice Distributor contract for rewards to the Sturdy protocol, using a staked token as rewards asset.
 * The contract stakes the rewards before redistributing them to the Sturdy protocol participants.
 * @author Sturdy
 **/
contract StableYieldDistribution is VersionedInitializable {
  using SafeERC20 for IERC20;

  struct AssetData {
    uint104 emissionPerSecond;
    uint104 index;
    uint40 lastUpdateTimestamp;
    mapping(address => uint256) users;
  }

  uint256 private constant REVISION = 2;
  uint8 private constant PRECISION = 27;
  address public immutable EMISSION_MANAGER;

  uint256 internal _distributionEnd;

  mapping(address => uint256) internal _usersUnclaimedRewards;
  ILendingPoolAddressesProvider internal _addressProvider;

  mapping(address => AssetData) public assets;
  address public REWARD_TOKEN;

  event AssetConfigUpdated(address indexed asset, uint256 emission);
  event AssetIndexUpdated(address indexed asset, uint256 index);
  event UserIndexUpdated(address indexed user, address indexed asset, uint256 index);
  event DistributionEndUpdated(uint256 newDistributionEnd);
  event RewardsAccrued(address indexed user, uint256 amount);
  event RewardsClaimed(
    address indexed user,
    address indexed to,
    address indexed claimer,
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

  function configureAssets(
    address[] calldata _assets,
    uint256[] calldata _emissionsPerSecond
  ) external payable onlyEmissionManager {
    uint256 length = _assets.length;
    require(length == _emissionsPerSecond.length, Errors.YD_INVALID_CONFIGURATION);

    DistributionTypes.AssetConfigInput[]
      memory assetsConfig = new DistributionTypes.AssetConfigInput[](_assets.length);

    for (uint256 i; i < length; ++i) {
      assetsConfig[i].underlyingAsset = _assets[i];
      assetsConfig[i].emissionPerSecond = uint104(_emissionsPerSecond[i]);

      require(
        assetsConfig[i].emissionPerSecond == _emissionsPerSecond[i],
        Errors.YD_INVALID_CONFIGURATION
      );

      assetsConfig[i].totalStaked = IScaledBalanceToken(_assets[i]).scaledTotalSupply();
    }
    _configureAssets(assetsConfig);
  }

  function handleAction(
    address user,
    address asset,
    uint256 totalSupply,
    uint256 userBalance
  ) external payable onlyIncentiveController {
    if (assets[asset].emissionPerSecond == 0) return;

    uint256 accruedRewards = _updateUserAssetInternal(user, asset, userBalance, totalSupply);
    if (accruedRewards != 0) {
      _usersUnclaimedRewards[user] += accruedRewards;
      emit RewardsAccrued(user, accruedRewards);
    }
  }

  function getRewardsBalance(
    address[] calldata _assets,
    address _user
  ) external view returns (uint256) {
    uint256 unclaimedRewards = _usersUnclaimedRewards[_user];
    uint256 length = _assets.length;
    DistributionTypes.UserStakeInput[] memory userState = new DistributionTypes.UserStakeInput[](
      length
    );
    for (uint256 i; i < length; ++i) {
      userState[i].underlyingAsset = _assets[i];
      (userState[i].stakedByUser, userState[i].totalStaked) = IScaledBalanceToken(_assets[i])
        .getScaledUserBalanceAndSupply(_user);
    }
    unclaimedRewards += _getUnclaimedRewards(_user, userState);
    return unclaimedRewards;
  }

  function claimRewards(
    address[] calldata _assets,
    uint256 _amount,
    address _to
  ) external returns (uint256) {
    require(_to != address(0), Errors.YD_INVALID_CONFIGURATION);
    return _claimRewards(_assets, _amount, msg.sender, msg.sender, _to);
  }

  function getUserUnclaimedRewards(address _user) external view returns (uint256) {
    return _usersUnclaimedRewards[_user];
  }

  function setRewardInfo(address tokenAddress) external payable onlyEmissionManager {
    REWARD_TOKEN = tokenAddress;
  }

  function setDistributionEnd(uint256 distributionEnd) external payable onlyEmissionManager {
    _distributionEnd = distributionEnd;
    emit DistributionEndUpdated(distributionEnd);
  }

  function getDistributionEnd() external view returns (uint256) {
    return _distributionEnd;
  }

  function getUserAssetData(address user, address asset) public view returns (uint256) {
    return assets[asset].users[user];
  }

  function getAssetData(address asset) public view returns (uint256, uint256, uint256) {
    return (
      assets[asset].index,
      assets[asset].emissionPerSecond,
      assets[asset].lastUpdateTimestamp
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
   * @param _assets reward asset list
   * @param _amount Amount of rewards to claim
   * @param _claimer claimer address which is same with _user
   * @param _user Address to check and claim rewards
   * @param _to Address that will be receiving the rewards
   * @return Rewards claimed
   **/
  function _claimRewards(
    address[] calldata _assets,
    uint256 _amount,
    address _claimer,
    address _user,
    address _to
  ) internal returns (uint256) {
    if (_amount == 0) {
      return 0;
    }
    uint256 unclaimedRewards = _usersUnclaimedRewards[_user];
    uint256 length = _assets.length;
    DistributionTypes.UserStakeInput[] memory userState = new DistributionTypes.UserStakeInput[](
      length
    );
    for (uint256 i; i < length; ++i) {
      userState[i].underlyingAsset = _assets[i];
      (userState[i].stakedByUser, userState[i].totalStaked) = IScaledBalanceToken(_assets[i])
        .getScaledUserBalanceAndSupply(_user);
    }

    uint256 accruedRewards = _claimRewards(_user, userState);
    if (accruedRewards != 0) {
      unclaimedRewards += accruedRewards;
      emit RewardsAccrued(_user, accruedRewards);
    }

    if (unclaimedRewards == 0) {
      return 0;
    }

    uint256 amountToClaim = _amount > unclaimedRewards ? unclaimedRewards : _amount;
    _usersUnclaimedRewards[_user] = unclaimedRewards - amountToClaim; // Safe due to the previous line

    IERC20 stakeToken = IERC20(REWARD_TOKEN);
    if (stakeToken.balanceOf(address(this)) >= amountToClaim) {
      stakeToken.safeTransfer(_to, amountToClaim);
    }

    emit RewardsClaimed(_user, _to, _claimer, amountToClaim);

    return amountToClaim;
  }

  /**
   * @dev Configure the assets for a specific emission
   * @param assetsConfigInput The array of each asset configuration
   **/
  function _configureAssets(
    DistributionTypes.AssetConfigInput[] memory assetsConfigInput
  ) internal {
    uint256 length = assetsConfigInput.length;
    for (uint256 i; i < length; ++i) {
      AssetData storage assetConfig = assets[assetsConfigInput[i].underlyingAsset];

      _updateAssetStateInternal(
        assetsConfigInput[i].underlyingAsset,
        assetConfig,
        assetsConfigInput[i].totalStaked
      );

      assetConfig.emissionPerSecond = assetsConfigInput[i].emissionPerSecond;

      emit AssetConfigUpdated(
        assetsConfigInput[i].underlyingAsset,
        assetsConfigInput[i].emissionPerSecond
      );
    }
  }

  /**
   * @dev Updates the state of one distribution, mainly rewards index and timestamp
   * @param asset The address of the asset being updated
   * @param assetConfig Storage pointer to the distribution's config
   * @param totalStaked Current total of staked assets for this distribution
   * @return The new distribution index
   **/
  function _updateAssetStateInternal(
    address asset,
    AssetData storage assetConfig,
    uint256 totalStaked
  ) internal returns (uint256) {
    uint256 oldIndex = assetConfig.index;
    uint256 emissionPerSecond = assetConfig.emissionPerSecond;
    uint128 lastUpdateTimestamp = assetConfig.lastUpdateTimestamp;

    if (block.timestamp == lastUpdateTimestamp) {
      return oldIndex;
    }

    uint256 newIndex = _getAssetIndex(
      oldIndex,
      emissionPerSecond,
      lastUpdateTimestamp,
      totalStaked
    );

    if (newIndex == oldIndex) {
      assetConfig.lastUpdateTimestamp = uint40(block.timestamp);
    } else {
      require(uint104(newIndex) == newIndex, 'Index overflow');
      //optimization: storing one after another saves one SSTORE
      assetConfig.index = uint104(newIndex);
      assetConfig.lastUpdateTimestamp = uint40(block.timestamp);
      emit AssetIndexUpdated(asset, newIndex);
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
    uint256 userIndex = assetData.users[user];
    uint256 accruedRewards;

    uint256 newIndex = _updateAssetStateInternal(asset, assetData, totalStaked);

    if (userIndex == newIndex) return accruedRewards;

    if (stakedByUser != 0) {
      accruedRewards = _getRewards(stakedByUser, newIndex, userIndex);
    }

    assetData.users[user] = newIndex;
    emit UserIndexUpdated(user, asset, newIndex);

    return accruedRewards;
  }

  /**
   * @dev Used by "frontend" stake contracts to update the data of an user when claiming rewards from there
   * @param user The address of the user
   * @param stakes List of structs of the user data related with his stake
   * @return The accrued rewards for the user until the moment
   **/
  function _claimRewards(
    address user,
    DistributionTypes.UserStakeInput[] memory stakes
  ) internal returns (uint256) {
    uint256 accruedRewards;
    uint256 length = stakes.length;
    for (uint256 i; i < length; ++i) {
      accruedRewards =
        accruedRewards +
        _updateUserAssetInternal(
          user,
          stakes[i].underlyingAsset,
          stakes[i].stakedByUser,
          stakes[i].totalStaked
        );
    }

    return accruedRewards;
  }

  /**
   * @dev Return the accrued rewards for an user over a list of distribution
   * @param user The address of the user
   * @param stakes List of structs of the user data related with his stake
   * @return The accrued rewards for the user until the moment
   **/
  function _getUnclaimedRewards(
    address user,
    DistributionTypes.UserStakeInput[] memory stakes
  ) internal view returns (uint256) {
    uint256 accruedRewards;
    uint256 length = stakes.length;
    for (uint256 i; i < length; ++i) {
      AssetData storage assetConfig = assets[stakes[i].underlyingAsset];
      uint256 assetIndex = _getAssetIndex(
        assetConfig.index,
        assetConfig.emissionPerSecond,
        assetConfig.lastUpdateTimestamp,
        stakes[i].totalStaked
      );

      accruedRewards =
        accruedRewards +
        _getRewards(stakes[i].stakedByUser, assetIndex, assetConfig.users[user]);
    }

    return accruedRewards;
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
    return (principalUserBalance * (reserveIndex - userIndex)) / 10 ** uint256(PRECISION);
  }

  /**
   * @dev Calculates the next value of an specific distribution index, with validations
   * @param currentIndex Current index of the distribution
   * @param emissionPerSecond Representing the total rewards distributed per second per asset unit, on the distribution
   * @param lastUpdateTimestamp Last moment this distribution was updated
   * @param totalBalance of tokens considered for the distribution
   * @return The new index.
   **/
  function _getAssetIndex(
    uint256 currentIndex,
    uint256 emissionPerSecond,
    uint128 lastUpdateTimestamp,
    uint256 totalBalance
  ) internal view returns (uint256) {
    uint256 distributionEnd = _distributionEnd;
    if (
      emissionPerSecond == 0 ||
      totalBalance == 0 ||
      lastUpdateTimestamp == block.timestamp ||
      lastUpdateTimestamp >= distributionEnd
    ) {
      return currentIndex;
    }

    uint256 currentTimestamp = block.timestamp > distributionEnd
      ? distributionEnd
      : block.timestamp;
    uint256 timeDelta = currentTimestamp - lastUpdateTimestamp;
    return
      ((emissionPerSecond * timeDelta * (10 ** uint256(PRECISION))) / totalBalance) + currentIndex;
  }
}