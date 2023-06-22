// SPDX-License-Identifier: LICENSED
pragma solidity ^0.7.0;

interface ICashBackManager {
    function cashBackEnable() external view returns (bool);

    function getCashBackPercent(uint256 level) external view returns (uint256);
}