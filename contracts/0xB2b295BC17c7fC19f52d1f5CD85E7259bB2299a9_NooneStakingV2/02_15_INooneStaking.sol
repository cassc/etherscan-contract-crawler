// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface INooneStaking {
    //events
    event Deposit(
        address indexed user,
        uint256 indexed pid,
        uint256 amount,
        uint256 lockTime
    );

    event Withdraw(
        address indexed user, 
        uint256 indexed pid, 
        uint256 amount
    );

    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );

    event NFTStaked(
        address indexed user,
        address indexed NFTContract,
        uint256 tokenID
    );

    event NFTWithdrawn(
        address indexed user,
        address indexed NFTContract,
        uint256 tokenID
    );

    event TokensLocked(
        address indexed user,
        uint256 timestamp,
        uint256 lockTime
    );

    event Emergency(uint256 timestamp, bool ifEmergency);

}