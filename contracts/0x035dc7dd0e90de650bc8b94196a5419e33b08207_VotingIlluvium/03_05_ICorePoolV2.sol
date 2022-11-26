// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/// @dev Data structure representing token holder using a pool.
struct V2User {
    /// @dev pending yield rewards to be claimed
    uint128 pendingYield;
    /// @dev pending revenue distribution to be claimed
    uint128 pendingRevDis;
    /// @dev Total weight
    uint248 totalWeight;
    /// @dev number of v1StakesIds
    uint8 v1IdsLength;
    /// @dev Checkpoint variable for yield calculation
    uint256 yieldRewardsPerWeightPaid;
    /// @dev Checkpoint variable for vault rewards calculation
    uint256 vaultRewardsPerWeightPaid;
}

struct V2Stake {
    /// @dev token amount staked
    uint120 value;
    /// @dev locking period - from
    uint64 lockedFrom;
    /// @dev locking period - until
    uint64 lockedUntil;
    /// @dev indicates if the stake was created as a yield reward
    bool isYield;
}

interface ICorePoolV2 {
    function users(address _user) external view returns (V2User memory);

    function poolToken() external view returns (address);

    function isFlashPool() external view returns (bool);

    function weight() external view returns (uint32);

    function lastYieldDistribution() external view returns (uint64);

    function yieldRewardsPerWeight() external view returns (uint256);

    function globalWeight() external view returns (uint256);

    function pendingRewards(address _user)
        external
        view
        returns (uint256, uint256);

    function poolTokenReserve() external view returns (uint256);

    function balanceOf(address _user) external view returns (uint256);

    function getTotalReserves() external view returns (uint256);

    function getStake(address _user, uint256 _stakeId)
        external
        view
        returns (V2Stake memory);

    function getV1StakeId(address _user, uint256 _position)
        external
        view
        returns (uint256);

    function getStakesLength(address _user) external view returns (uint256);

    function sync() external;

    function setWeight(uint32 _weight) external;

    function receiveVaultRewards(uint256 value) external;
}