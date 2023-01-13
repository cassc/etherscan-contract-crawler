// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface IBribe {
    function getReward(uint256 tokenId, address[] memory tokens) external;

    function rewardsList() external view returns (address[] memory);
}