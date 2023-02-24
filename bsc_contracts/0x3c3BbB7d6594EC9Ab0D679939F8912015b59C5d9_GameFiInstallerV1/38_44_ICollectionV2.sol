// SPDX-License-Identifier: BUSL-1.1
// GameFi Core™ by CDEVS

pragma solidity 0.8.10;

import "../../type/ITokenTypes.sol";

interface ICollectionV2 is ITokenTypes {
    struct Collection {
        TokenStandart tokenStandart;
        address implementation;
        address tokenContract;
        bool isActive;
    }

    event CreateCollection(
        address indexed sender,
        uint256 indexed collectionId,
        Collection collection,
        address implementation,
        uint256 salt,
        string name,
        string symbol,
        string contractURI,
        string tokenURI,
        bytes data,
        uint256 timestamp
    );

    event SetCollectionActivity(
        address indexed sender,
        uint256 indexed collectionId,
        bool newStatus,
        uint256 timestamp
    );

    function createCollection(
        TokenStandart tokenStandart,
        address implementation,
        uint256 salt,
        string memory name_,
        string memory symbol_,
        string memory contractURI_,
        string memory tokenURI_,
        bytes memory data
    ) external returns (address);

    function setCollectionActivity(uint256 collectionId, bool isActive) external;

    function callToCollection(uint256[] memory collectionId, bytes[] memory data)
        external
        returns (bytes[] memory result);

    function collectionDetails(uint256 collectionId) external view returns (Collection memory);

    function totalCollections() external view returns (uint256);
}