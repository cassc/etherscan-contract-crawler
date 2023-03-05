// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface IBooster {
    struct PoolInfo {
        address lptoken;
        address token;
        address gauge;
        address crvRewards;
        address stash;
        bool shutdown;
    }
    function poolInfo(uint pid) external view returns(PoolInfo memory);
    function deposit(uint _pid, uint _amount, bool _stake) external returns(bool);
}