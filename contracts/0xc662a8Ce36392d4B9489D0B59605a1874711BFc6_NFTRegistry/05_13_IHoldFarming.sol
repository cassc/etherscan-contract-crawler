// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


interface IHoldFarming {
    function curateCollection (address nftAddress) external;
    function holdFarmingBlocks(address nftAddress) external view returns (uint256, uint256);
    function initiateHoldFarmingForNFT(address nftAddress, uint256 tokenId) external;
    function updateCollectionPools() external;
    function updatePoolFor(address nftAddress) external;
}