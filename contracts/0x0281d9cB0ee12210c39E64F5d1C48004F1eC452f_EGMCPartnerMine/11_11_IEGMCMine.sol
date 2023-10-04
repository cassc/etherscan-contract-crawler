// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IEGMCMine {
    function getMiningPower(address _user) external view returns (uint);
}