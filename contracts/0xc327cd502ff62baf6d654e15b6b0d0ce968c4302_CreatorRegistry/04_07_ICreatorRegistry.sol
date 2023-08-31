// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface ICreatorRegistry {
    function getCreatorOf(address nftContract_, uint256 tokenId_) external view returns (address);
}