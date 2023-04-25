// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

/**
 * @dev Interface of the MasterWombat
 */
interface IMasterWombatV3Reader {
    function poolLength() external view returns (uint256);
    struct WombatV3Pool {
        address lpToken; // Address of LP token contract.
        ////
        address rewarder;
        uint40 periodFinish;
        ////
        uint128 sumOfFactors; // 20.18 fixed point. the sum of all boosted factors by all of the users in the pool
        uint128 rewardRate; // 20.18 fixed point.
        ////
        uint104 accWomPerShare; // 19.12 fixed point. Accumulated WOM per share, times 1e12.
        uint104 accWomPerFactorShare; // 19.12 fixed point. Accumulated WOM per factor share
        uint40 lastRewardTimestamp;
    }
    function poolInfoV3(uint256 poolId) external view returns (WombatV3Pool memory);
    //amount uint128, factor uint128, rewardDebt uint128, pendingWom uint128
    function userInfo(uint256 poolId, address account) external view  returns (uint128,  uint128,  uint128,  uint128);
}