// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICollectionManager {
    function addCollection(address collection) external;

    function removeCollection(address collection) external;

    function isCollectionWhitelisted(address collection) external view returns (bool);

    function viewWhitelistedCollections(uint256 cursor, uint256 size) external view returns (address[] memory, uint256);

    function viewCountWhitelistedCollections() external view returns (uint256);
}