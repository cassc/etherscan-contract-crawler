// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.7.5;
pragma experimental ABIEncoderV2;

import './lib/DistributionTypes.sol';
import './interfaces/IStakingRewards.sol';

import '@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol';
import '../../../utils/SafeMathUint128.sol';
import '@openzeppelin/contracts-upgradeable/proxy/Initializable.sol';
import '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';

/**
 * @title StakingRewards
 * @notice Accounting contract to manage multiple staking distributions
 * @author Aave / Ethichub
 **/
contract StakingRewards is Initializable, IStakingRewards, AccessControlUpgradeable {
    bytes32 public constant EMISSION_MANAGER_ROLE = keccak256('EMISSION_MANAGER');
    using SafeMathUpgradeable for uint256;
    using SafeMathUint128 for uint128;

    struct AssetData {
        uint128 emissionPerSecond;
        uint128 lastUpdateTimestamp;
        uint256 index;
        mapping(address => uint256) users;
    }

    uint256 public DISTRIBUTION_END;

    uint8 constant public PRECISION = 18;

    mapping(address => AssetData) public assets;

    event AssetConfigUpdated(address indexed asset, uint256 emission);
    event AssetIndexUpdated(address indexed asset, uint256 index);
    event UserIndexUpdated(address indexed user, address indexed asset, uint256 index);
    event DistributionEndChanged(uint256 distributionEnd);

    function __StakingRewards_init(address emissionManager, uint256 distributionDuration)
        public
        initializer
    {
        __AccessControl_init_unchained();
        DISTRIBUTION_END = block.timestamp.add(distributionDuration);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(EMISSION_MANAGER_ROLE, emissionManager);
    }

    /**
     * @dev Configures the distribution of rewards for a list of assets
     * @param assetsConfigInput The list of configurations to apply
     **/
    function configureAssets(DistributionTypes.AssetConfigInput[] memory assetsConfigInput)
        public
        override
    {
        require(hasRole(EMISSION_MANAGER_ROLE, msg.sender), 'ONLY_EMISSION_MANAGER');

        for (uint256 i = 0; i < assetsConfigInput.length; i++) {
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
     * @notice Change distribution end datetime
     * @param _distributionEndDate new distribution end datetime (UNIX Timestamp)
     */
    function changeDistributionEndDate(uint256 _distributionEndDate) public override {
        require(hasRole(EMISSION_MANAGER_ROLE, msg.sender), 'ONLY_EMISSION_MANAGER');
        return _changeDistributionEndDate(_distributionEndDate);
    }

    /**
     * @notice Change distribution end datetime internal function
     * @param _distributionEndDate new distribution end datetime (UNIX Timestamp)
     */
    function _changeDistributionEndDate(uint256 _distributionEndDate) internal {
        DISTRIBUTION_END = _distributionEndDate;
        emit DistributionEndChanged(DISTRIBUTION_END);
    }

    /**
     * @dev Updates the state of one distribution, mainly rewards index and timestamp
     * @param underlyingAsset The address used as key in the distribution
     * @param assetConfig Storage pointer to the distribution's config
     * @param totalStaked Current total of staked assets for this distribution
     * @return The new distribution index
     **/
    function _updateAssetStateInternal(
        address underlyingAsset,
        AssetData storage assetConfig,
        uint256 totalStaked
    ) internal returns (uint256) {
        uint256 oldIndex = assetConfig.index;
        uint128 lastUpdateTimestamp = assetConfig.lastUpdateTimestamp;

        if (block.timestamp == lastUpdateTimestamp) {
            return oldIndex;
        }

        uint256 newIndex =
            _getAssetIndex(
                oldIndex,
                assetConfig.emissionPerSecond,
                lastUpdateTimestamp,
                totalStaked
            );

        if (newIndex != oldIndex) {
            assetConfig.index = newIndex;
            emit AssetIndexUpdated(underlyingAsset, newIndex);
        }

        assetConfig.lastUpdateTimestamp = uint128(block.timestamp);

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
        uint256 accruedRewards = 0;

        uint256 newIndex = _updateAssetStateInternal(asset, assetData, totalStaked);

        if (userIndex != newIndex) {
            if (stakedByUser != 0) {
                accruedRewards = _getRewards(stakedByUser, newIndex, userIndex);
            }

            assetData.users[user] = newIndex;
            emit UserIndexUpdated(user, asset, newIndex);
        }

        return accruedRewards;
    }

    /**
     * @dev Used by "frontend" stake contracts to update the data of an user when claiming rewards from there
     * @param user The address of the user
     * @param stakes List of structs of the user data related with his stake
     * @return The accrued rewards for the user until the moment
     **/
    function _claimRewards(address payable user, DistributionTypes.UserStakeInput[] memory stakes)
        internal
        returns (uint256)
    {
        uint256 accruedRewards = 0;

        for (uint256 i = 0; i < stakes.length; i++) {
            accruedRewards = accruedRewards.add(
                _updateUserAssetInternal(
                    user,
                    stakes[i].underlyingAsset,
                    stakes[i].stakedByUser,
                    stakes[i].totalStaked
                )
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
    function _getUnclaimedRewards(address user, DistributionTypes.UserStakeInput[] memory stakes)
        internal
        view
        returns (uint256)
    {
        uint256 accruedRewards = 0;

        for (uint256 i = 0; i < stakes.length; i++) {
            AssetData storage assetConfig = assets[stakes[i].underlyingAsset];
            uint256 assetIndex =
                _getAssetIndex(
                    assetConfig.index,
                    assetConfig.emissionPerSecond,
                    assetConfig.lastUpdateTimestamp,
                    stakes[i].totalStaked
                );

            accruedRewards = accruedRewards.add(
                _getRewards(stakes[i].stakedByUser, assetIndex, assetConfig.users[user])
            );
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
    ) internal view returns (uint256) {
        return principalUserBalance.mul(reserveIndex.sub(userIndex)).div(10**uint256(PRECISION));
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
        if (
            emissionPerSecond == 0 ||
            totalBalance == 0 ||
            lastUpdateTimestamp == block.timestamp ||
            lastUpdateTimestamp >= DISTRIBUTION_END
        ) {
            return currentIndex;
        }

        uint256 currentTimestamp =
            block.timestamp > DISTRIBUTION_END ? DISTRIBUTION_END : block.timestamp;
        uint256 timeDelta = currentTimestamp.sub(lastUpdateTimestamp);
        return
            emissionPerSecond.mul(timeDelta).mul(10**uint256(PRECISION)).div(totalBalance).add(
                currentIndex
            );
    }

    /**
     * @dev Returns the data of an user on a distribution
     * @param user Address of the user
     * @param asset The address of the reference asset of the distribution
     * @return The new index
     **/
    function getUserAssetData(address user, address asset) public view returns (uint256) {
        return assets[asset].users[user];
    }
}