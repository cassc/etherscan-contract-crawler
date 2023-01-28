// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMultiRewarder {
    function earned(
        address pool, 
        address user, 
        address reward
    ) external view returns (uint256);

     function getReward(address pool)
        external;
}