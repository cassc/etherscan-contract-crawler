// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IIFRetrievableStakeWeight {
    function getTotalStakeWeight(uint24 trackId, uint80 timestamp)
        external
        view
        returns (uint192);

    function getUserStakeWeight(
        uint24 trackId,
        address user,
        uint80 timestamp
    ) external view returns (uint192);
}