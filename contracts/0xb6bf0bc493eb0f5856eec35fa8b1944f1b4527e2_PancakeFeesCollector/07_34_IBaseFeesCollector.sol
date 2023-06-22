// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBaseFeesCollector {
    function collectFeesData(address vault) external view returns (address[] memory tokens, uint256[] memory amounts);
}