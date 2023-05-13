// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ILaunchpadIDO {
    function raised() external view returns (uint256);
    function contributed(address account) external view returns (uint256);
}

interface IOldLaunchpadIDO {
    function balances(address account) external view returns (uint256);
}