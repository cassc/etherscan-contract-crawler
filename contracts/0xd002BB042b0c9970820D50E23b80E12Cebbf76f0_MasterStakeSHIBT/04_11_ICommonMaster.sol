// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

interface ICommonMaster {
    event Stake(address indexed user, address indexed poolAddress, uint256 amount);
    event Unstake(address indexed user, address indexed poolAddress, uint256 amount);
    event EmergencyUnstake(address indexed user, address indexed poolAddress, uint256 amount);
    event SetTokenPerBlock(address indexed user, uint256 tokenPerBlock);
    event SetTotalToBeMintAmount(address indexed user, uint256 oldTotalToBeMintAmount, uint256 newTotalToBeMintAmount);

    // *** POOL MANAGER ***
    function poolLength() external view returns (uint256);

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(
        uint256 _allocPoint,
        address _pair,
        bool _withUpdate
    ) external;

    // Update the given pool's TOKEN allocation point. Can only be called by the owner.
    function set(
        address _pair,
        uint256 _allocPoint,
        bool _withUpdate
    ) external;

    function setLastRewardBlock(address _pair, uint256 _lastRewardBlock) external;

    function poolUserInfoMap(address, address) external view returns (uint256, uint256);

    // Return total reward over the given _from to _to block.
    function getTotalReward(uint256 _from, uint256 _to) external view returns (uint256 totalReward);

    // View function to see pending TOKENs on frontend.
    function pendingToken(address _pair, address _user) external view returns (uint256);

    // Update reward vairables for all pools. Be careful of gas spending!
    function massUpdatePools() external;

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(address _pair) external;

    // Stake LP tokens to TokenMaster for TOKEN allocation.
    function stake(address _pair, uint256 _amount) external;

    // Unstake LP tokens from TokenMaster.
    function unstake(address _pair, uint256 _amount) external;

    // Unstake without caring about rewards. EMERGENCY ONLY.
    function emergencyUnstake(address _pair, uint256 _amount) external;

    function pauseStake() external;

    function unpauseStake() external;

    function setTokenPerBlock(uint256 _tokenPerBlock) external;
}