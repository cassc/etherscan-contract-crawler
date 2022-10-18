// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

pragma abicoder v2;

interface IRageQuit {
    function rageQuit() external;
}

interface IAludel is IRageQuit {
    /* admin events */

    event AludelCreated(address rewardPool, address powerSwitch);
    event AludelFunded(uint256 amount, uint256 duration);
    event BonusTokenRegistered(address token);
    event VaultFactoryRegistered(address factory);
    event VaultFactoryRemoved(address factory);

    /* user events */

    event Staked(address vault, uint256 amount);
    event Unstaked(address vault, uint256 amount);
    event RewardClaimed(address vault, address token, uint256 amount);

    /* data types */

    struct AludelData {
        address stakingToken;
        address rewardToken;
        address rewardPool;
        RewardScaling rewardScaling;
        uint256 rewardSharesOutstanding;
        uint256 totalStake;
        uint256 totalStakeUnits;
        uint256 lastUpdate;
        RewardSchedule[] rewardSchedules;
    }

    struct RewardSchedule {
        uint256 duration;
        uint256 start;
        uint256 shares;
    }

    struct VaultData {
        uint256 totalStake;
        StakeData[] stakes;
    }

    struct StakeData {
        uint256 amount;
        uint256 timestamp;
    }

    struct RewardScaling {
        uint256 floor;
        uint256 ceiling;
        uint256 time;
    }

    struct RewardOutput {
        uint256 lastStakeAmount;
        uint256 newStakesCount;
        uint256 reward;
        uint256 newTotalStakeUnits;
    }

    function initializeLock() external;

    function initialize(
        uint64 startTime,
        address ownerAddress,
        address feeRecipient,
        uint16 feeBps,
        bytes calldata
    ) external;

    /* user functions */

    function stake(address vault, uint256 amount, bytes calldata permission)
        external;

    function unstakeAndClaim(
        address vault,
        uint256 amount,
        bytes calldata permission
    )
        external;

    /* admin functions */

    function fund(uint256 amount, uint256 duration) external;

    function registerVaultFactory(address factory) external;

    function removeVaultFactory(address factory) external;

    function registerBonusToken(address bonusToken) external;

    function rescueTokensFromRewardPool(
        address token,
        address recipient,
        uint256 amount
    )
        external;

    /* getter functions */

    function getAludelData()
        external
        view
        returns (AludelData memory aludel);

    function getBonusTokenSetLength()
        external
        view
        returns (uint256 length);

    function getBonusTokenAtIndex(uint256 index)
        external
        view
        returns (address bonusToken);

    function getVaultFactorySetLength()
        external
        view
        returns (uint256 length);

    function getVaultFactoryAtIndex(uint256 index)
        external
        view
        returns (address factory);

    function getVaultData(address vault)
        external
        view
        returns (VaultData memory vaultData);

    function isValidAddress(address target)
        external
        view
        returns (bool validity);

    function isValidVault(address target)
        external
        view
        returns (bool validity);

    function getCurrentUnlockedRewards()
        external
        view
        returns (uint256 unlockedRewards);

    function getFutureUnlockedRewards(uint256 timestamp)
        external
        view
        returns (uint256 unlockedRewards);

    function getCurrentVaultReward(address vault)
        external
        view
        returns (uint256 reward);

    function getCurrentStakeReward(address vault, uint256 stakeAmount)
        external
        view
        returns (uint256 reward);

    function getFutureVaultReward(address vault, uint256 timestamp)
        external
        view
        returns (uint256 reward);

    function getFutureStakeReward(
        address vault,
        uint256 stakeAmount,
        uint256 timestamp
    )
        external
        view
        returns (uint256 reward);

    function getCurrentVaultStakeUnits(address vault)
        external
        view
        returns (uint256 stakeUnits);

    function getFutureVaultStakeUnits(address vault, uint256 timestamp)
        external
        view
        returns (uint256 stakeUnits);

    function getCurrentTotalStakeUnits()
        external
        view
        returns (uint256 totalStakeUnits);

    function getFutureTotalStakeUnits(uint256 timestamp)
        external
        view
        returns (uint256 totalStakeUnits);

    /* pure functions */

    function calculateTotalStakeUnits(
        StakeData[] memory stakes,
        uint256 timestamp
    )
        external
        pure
        returns (uint256 totalStakeUnits);

    function calculateStakeUnits(uint256 amount, uint256 start, uint256 end)
        external
        pure
        returns (uint256 stakeUnits);

    function calculateUnlockedRewards(
        RewardSchedule[] memory rewardSchedules,
        uint256 rewardBalance,
        uint256 sharesOutstanding,
        uint256 timestamp
    )
        external
        pure
        returns (uint256 unlockedRewards);

    function calculateRewardFromStakes(
        StakeData[] memory stakes,
        uint256 unstakeAmount,
        uint256 unlockedRewards,
        uint256 totalStakeUnits,
        uint256 timestamp,
        RewardScaling memory rewardScaling
    )
        external
        pure
        returns (RewardOutput memory out);

    function calculateReward(
        uint256 unlockedRewards,
        uint256 stakeAmount,
        uint256 stakeDuration,
        uint256 totalStakeUnits,
        RewardScaling memory rewardScaling
    )
        external
        pure
        returns (uint256 reward);
}