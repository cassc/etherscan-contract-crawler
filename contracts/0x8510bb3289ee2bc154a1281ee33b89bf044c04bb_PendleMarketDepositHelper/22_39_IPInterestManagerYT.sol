// SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

interface IPInterestManagerYT {
    function userInterest(
        address user
    ) external view returns (uint128 lastPYIndex, uint128 accruedInterest);
}