// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IRandMath {
    function seed(uint256 initQty) external;

    function getMaxRandNumInRange(
        uint32 maxLoops,
        uint32 range,
        uint32 peak
    ) external view returns (uint32, uint32);
}