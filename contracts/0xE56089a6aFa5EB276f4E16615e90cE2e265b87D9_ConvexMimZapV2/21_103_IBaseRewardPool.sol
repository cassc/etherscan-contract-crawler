// SPDX-License-Identifier: MIT
pragma solidity 0.6.11;

interface IRewardPool {
    /// @notice withdraw to a convex tokenized deposit
    function withdraw(uint256 _amount, bool _claim) external returns (bool);

    /// @notice claim rewards
    function getReward() external returns (bool);

    /// @notice stake a convex tokenized deposit
    function stake(uint256 _amount) external returns (bool);

    /// @notice Return how much rewards an address will receive if they claim their rewards now.
    function earned(address account) external view returns (uint256);

    /// @notice get balance of an address
    function balanceOf(address _account) external view returns (uint256);

    /// @notice get reward period end time
    /// @dev since this is based on the unipool contract, `notifyRewardAmount`
    /// must be called in order for a new period to begin.
    function periodFinish() external view returns (uint256);
}

interface IBaseRewardPool is IRewardPool {
    /// @notice withdraw directly to curve LP token
    function withdrawAndUnwrap(uint256 _amount, bool _claim)
        external
        returns (bool);

    /// @notice Return the number of extra rewards.
    function extraRewardsLength() external view returns (uint256);

    /** @notice array of child reward contracts
     * You can query the number of extra rewards via baseRewardPool.extraRewardsLength().
     * This array holds a list of VirtualBalanceRewardPool contracts which are similar in
     * nature to the base reward contract but without actual control of staked tokens.
     *
     * This means that if a pool has CRV rewards as well as SNX rewards, the pool's main
     * reward contract (BaseRewardPool) will distribute the CRV and the child contract
     * (VirtualBalanceRewardPool) will distribute the SNX.
     */
    function extraRewards(uint256 index) external view returns (address);
}