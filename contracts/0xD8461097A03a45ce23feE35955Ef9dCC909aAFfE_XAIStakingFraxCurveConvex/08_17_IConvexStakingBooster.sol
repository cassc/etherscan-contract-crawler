//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IConvexStakingBooster {
    function createVault(uint256 _pid) external returns (address);
}