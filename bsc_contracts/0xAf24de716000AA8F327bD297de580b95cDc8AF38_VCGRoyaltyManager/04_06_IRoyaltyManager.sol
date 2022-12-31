// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IRoyaltyManager {
    struct CollectionInfo {
        uint256 collectionRoyalty;
        address collectionTaker;
    }

    function getCollectionRoyaltyInfo(address collectionAddress)
        external
        view
        returns (CollectionInfo memory);

    function getMainCollectionRoyaltyInfo(address collectionAddress, uint nftId)
        external
        view
        returns (CollectionInfo memory);

    function addRoyalty(
        address collectionAddress,
        uint256 sellAmount,
        address _token,
        uint _nftId
    ) external returns (uint256);

    function withdrawRoyalty(
        address collectionAddress,
        address _token,
        uint256 _nftId
    ) external returns (uint256);

    function checkVCGNFT(address _collection) external view returns (bool);
}