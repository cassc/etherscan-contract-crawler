// SPDX-License-Identifier: ISC

pragma solidity ^0.8.13;

interface IBooster {
    struct PoolInfo {
        address lptoken;
        address token;
        address gauge;
        address crvRewards;
        address stash;
        bool shutdown;
    }

    function poolInfo(uint256 _pid) external view returns (PoolInfo memory);

    function deposit(
        uint256 _pid,
        uint256 _amount,
        bool _stake
    ) external returns (bool);

    function earmarkRewards(uint256 _pid) external returns (bool);

    function depositAll(uint256 _pid, bool _stake) external returns (bool);

    function withdraw(uint256 _pid, uint256 _amount) external returns (bool);

    function withdrawAll(uint256 _pid) external returns (bool);
}