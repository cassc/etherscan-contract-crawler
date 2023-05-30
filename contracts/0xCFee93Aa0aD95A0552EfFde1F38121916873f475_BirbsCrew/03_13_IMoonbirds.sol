// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface IMoonbirds {
    function ownerOf(uint256 tokenId) external view returns (address);

    function nestingPeriod(uint256 tokenId) external view returns (bool nesting, uint256 current, uint256 total);
}