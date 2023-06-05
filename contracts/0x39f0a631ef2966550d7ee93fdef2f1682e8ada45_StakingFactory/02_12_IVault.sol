//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IVault {
    function setStaking(address _newStaking) external;

    function sendReward(uint256 amount, address user) external;
}