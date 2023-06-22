// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.17;

interface IFPD {
    struct CollectionInfo {
        address authorizer;
        uint96 startId;
        uint96 supply;
        uint96 editionSize;
    }
    function collectionInfo(address) external view returns (CollectionInfo memory);
    function deedsClaimed(uint256) external view returns (uint256);
    function getArtTokenIdFromDeedId(uint256) external view returns (uint256);
    function getCollectionFromDeedId(uint256) external view returns (address);
    function printFactory() external view returns (address);
}