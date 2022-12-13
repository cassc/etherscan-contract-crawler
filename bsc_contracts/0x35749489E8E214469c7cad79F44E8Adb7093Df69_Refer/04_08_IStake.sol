// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IStake {
    function updateDynamic(address addr, uint amount) external returns (uint left);

    function getUserPower(address addr) external view returns (uint);
}