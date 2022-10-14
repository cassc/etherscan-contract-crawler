// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRewards {

    function initialize(
        address sellingToken,
        uint256[] memory timestamps,
        uint256[] memory prices,
        uint256[] memory thresholds,
        uint256[] memory bonuses
    ) external;
}