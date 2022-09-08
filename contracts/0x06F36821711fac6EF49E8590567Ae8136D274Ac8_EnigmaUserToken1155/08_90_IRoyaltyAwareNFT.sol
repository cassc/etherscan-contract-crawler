// SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

interface IRoyaltyAwareNFT {
    function royaltyFee(uint256 tokenId) external view returns (uint256);

    function getCreator(uint256 tokenId) external view returns (address);
}