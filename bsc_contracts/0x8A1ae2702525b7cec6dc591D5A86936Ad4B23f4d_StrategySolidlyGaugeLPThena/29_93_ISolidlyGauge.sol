// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

interface ISolidlyGauge {
    function getReward(uint256 tokenId, address[] memory rewards) external;
}