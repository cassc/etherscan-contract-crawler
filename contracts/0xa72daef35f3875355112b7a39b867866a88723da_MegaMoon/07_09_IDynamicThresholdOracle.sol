// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDynamicThresholdOracle {
    function getBuyThreshold() external view returns (uint);
}