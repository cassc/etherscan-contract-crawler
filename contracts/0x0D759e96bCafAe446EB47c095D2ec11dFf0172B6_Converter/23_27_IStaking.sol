// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

/**
 * @dev For testing purpose
 */
interface IStaking {
    event Staked(string tokenName, address indexed staker, uint256 timestamp, uint256 amount);
    event UnStaked(string tokenName, address indexed staker, uint256 timestamp, uint256 amount);

    struct Stake {
        uint256 time; // Time for precise calculations
        uint256 amount; // New amount on every new (un)stake
    }
}