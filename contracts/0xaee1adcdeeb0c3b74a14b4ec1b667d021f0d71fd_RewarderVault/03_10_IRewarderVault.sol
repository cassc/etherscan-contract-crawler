// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRewarderVault {
    event UpdateGuardian(address newGuard);
    event UpdateRewarder(address newRewarder);
    function rewarder() external returns(address);
    function setGuardian(address newGuardian) external;
    function lock() external;
    function updateRewarder(address newRewarder) external;
    function fillVault(uint256 amount) external;
}