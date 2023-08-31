//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IStakingFactory {
    function addUserStaking(address user) external;

    function removeUserStaking(address user) external;
}