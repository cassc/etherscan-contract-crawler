// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IArrakisV2Beacon {
    function implementation() external view returns (address);
}