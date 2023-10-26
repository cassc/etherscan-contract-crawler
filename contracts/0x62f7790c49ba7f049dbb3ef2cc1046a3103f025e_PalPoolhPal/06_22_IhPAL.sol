pragma solidity ^0.7.6;
pragma abicoder v2;
//SPDX-License-Identifier: MIT

interface IhPAL {

    struct UserLock {
        uint128 amount;
        uint48 startTimestamp;
        uint48 duration;
        uint32 fromBlock;
    }

    // solhint-disable-next-line
    function MIN_LOCK_DURATION() external view returns(uint256);
    // solhint-disable-next-line
    function MAX_LOCK_DURATION() external view returns(uint256);

    function getUserLock(address user) external view returns(UserLock memory);

    function getUserLockCount(address user) external view returns(uint256);

    function getUserPastLock(address user, uint256 blockNumber) external view returns(UserLock memory);

    function getCurrentVotes(address user) external view returns(uint256);

    function getPastVotes(address user) external view returns(uint256);

    function estimateClaimableRewards(address user) external view returns(uint256);

    function userRewardIndex(address user) external view returns (uint256);

    function rewardsLastUpdate(address user) external view returns (uint256);

    function pal() external view returns(address);


    function stake(uint256 amount) external returns(uint256);

    function cooldown() external;

    function unstake(uint256 amount, address receiver) external returns(uint256);

    function lock(uint256 amount, uint256 duration) external;

    function increaseLockDuration(uint256 duration) external;

    function increaseLock(uint256 amount) external;

    function unlock() external;

    function kick(address user) external;

    function stakeAndLock(uint256 amount, uint256 duration) external returns(uint256);

    function stakeAndIncreaseLock(uint256 amount, uint256 duration) external returns(uint256);

    function delegate(address delegatee) external;

    function claim(uint256 amount) external;

    function updateRewardState() external;

    function updateUserRewardState(address user) external;

}