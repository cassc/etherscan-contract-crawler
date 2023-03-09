// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IPool {
    function initialize(address token) external;

    function totalSupply() external view returns (uint256);
}

interface IStakingFactory {
    event StakingPoolCreated(address indexed token, address indexed stakingPool);
    event LockPeriodUpdated(uint256 oldLockPeriod, uint256 newLockPeriod);

    error StakingPoolAlreadyExists(address token, address stakingPool);

    /// @notice creates a new staking pool for the given token
    /// @param token the token to create a staking pool for
    function createStakingPool(address token) external;

    /// @notice updates the time tokens are locked after deposit
    function updateLockPeriod(uint256 newLockPeriod) external;

    /// @notice current lock period
    /// @return lock period in seconds
    function lockPeriod() external view returns (uint256);

    /// @notice returns the staking pool for the given token
    /// @dev if a pool has no tokens staked, returns address(0)
    /// @param token the token to get the staking pool for
    /// @return staking pool address
    function getPoolForRewardDistribution(address token) external view returns (address);
}