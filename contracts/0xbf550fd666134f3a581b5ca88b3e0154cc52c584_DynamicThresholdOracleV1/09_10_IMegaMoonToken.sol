// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMegaMoonToken {
    function router() external view returns (address);
    function pair() external view returns (address);
    function updateOracle(address) external;
}