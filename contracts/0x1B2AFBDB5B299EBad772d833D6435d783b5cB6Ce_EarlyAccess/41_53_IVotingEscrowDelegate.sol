// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IVotingEscrowDelegate {
    event Withdraw(address indexed addr, uint256 amount, uint256 penaltyRate);

    function withdraw(address addr, uint256 penaltyRate) external;
}