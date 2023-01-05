// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface IBribe {
    function getReward(uint tokenId, address[] memory tokens) external;
}