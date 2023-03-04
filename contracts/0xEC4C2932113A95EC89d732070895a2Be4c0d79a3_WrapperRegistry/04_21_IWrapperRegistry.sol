// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

interface IWrapperRegistry {
    event WrapperRegistered(address indexed wrapper);
    event WrapperUnregistered(address indexed wrapper);

    function registerWrapper(address wrapper) external;

    function unregisterWrapper(address wrapper) external;

    function findWrappers(address collection, uint256 tokenId) external returns (address[] memory wrapper);

    function isRegistered(address wrapper) external view returns (bool);

    function viewCollectionWrapperCount(address collection) external view returns (uint256);

    function viewCollectionWrappers(
        address collection,
        uint256 cursor,
        uint256 size
    ) external view returns (address[] memory, uint256);
}