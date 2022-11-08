// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

interface IStaking {
    function getDepositedAmount(address user) external view returns (uint256);
    //function userDeposits(address user) external view returns (
    //        uint256, uint256, uint256, uint256, uint256, bool);
}