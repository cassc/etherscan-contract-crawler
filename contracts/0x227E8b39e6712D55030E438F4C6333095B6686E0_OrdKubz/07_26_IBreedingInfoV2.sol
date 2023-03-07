// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IBreedingInfoV2 {
    function getHoldingSinceExternal(uint256 tokenId) external view returns (uint256);

    function ownerOfGenesis(uint256 tokenId) external view returns (address);
}