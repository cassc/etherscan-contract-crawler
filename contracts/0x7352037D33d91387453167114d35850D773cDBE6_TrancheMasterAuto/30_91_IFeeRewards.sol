// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface IFeeRewards {
    function sendRewards(uint256 _amount) external;
}