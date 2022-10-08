// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IManager {
    function managerFeeBPS() external view returns (uint16);
}