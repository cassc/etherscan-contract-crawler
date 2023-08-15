// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

interface ITheGardenNFT {
    function latestArrangement() external view returns (uint256);

    function arrangementForToken(uint256 id) external view returns (uint256);

    function hasTokenBeenReleased(uint256) external view returns (bool);
}