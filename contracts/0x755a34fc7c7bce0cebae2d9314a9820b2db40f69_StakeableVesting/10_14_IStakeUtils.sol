//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ITransferUtils.sol";

interface IStakeUtils is ITransferUtils{
    event Staked(
        address indexed user,
        uint256 amount,
        uint256 mintedShares,
        uint256 userUnstaked,
        uint256 userShares,
        uint256 totalShares,
        uint256 totalStake
        );

    event ScheduledUnstake(
        address indexed user,
        uint256 amount,
        uint256 shares,
        uint256 scheduledFor,
        uint256 userShares
        );

    event Unstaked(
        address indexed user,
        uint256 amount,
        uint256 userUnstaked,
        uint256 totalShares,
        uint256 totalStake
        );

    function stake(uint256 amount)
        external;

    function depositAndStake(uint256 amount)
        external;

    function scheduleUnstake(uint256 amount)
        external;

    function unstake(address userAddress)
        external
        returns (uint256);

    function unstakeAndWithdraw()
        external;
}