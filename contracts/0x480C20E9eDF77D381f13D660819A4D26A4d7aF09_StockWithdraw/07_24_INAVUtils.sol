// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface INAVUtils {
    function getConvexNAV(address) external view returns (uint256);
}