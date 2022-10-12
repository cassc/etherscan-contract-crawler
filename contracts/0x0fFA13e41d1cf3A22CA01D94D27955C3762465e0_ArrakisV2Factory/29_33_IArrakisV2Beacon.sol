// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IArrakisV2Beacon {
    function implementation() external view returns (address);
}