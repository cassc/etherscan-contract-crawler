// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICvgRewards {
    function cvgCycleRewards() external view returns (uint256);
}