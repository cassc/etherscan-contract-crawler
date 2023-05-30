//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.10;

interface IRandom {
    function random(uint256 tokenId) external view returns (uint256);
}