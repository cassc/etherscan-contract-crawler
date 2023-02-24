// SPDX-License-Identifier: BUSL-1.1
// GameFi Core™ by CDEVS

pragma solidity 0.8.10;

import "../../type/ITokenTypes.sol";

interface ITokenV2 is ITokenTypes {
    struct CollectionToken {
        uint256 collectionId;
        uint256 tokenId;
        uint256 amount;
    }

    event MintTokenToProfile(
        address indexed sender,
        CollectionToken collectionToken,
        uint256 indexed profileId,
        bytes data,
        uint256 timestamp
    );

    event BurnTokenFromProfile(
        address indexed sender,
        CollectionToken collectionToken,
        uint256 indexed profileId,
        bytes data,
        uint256 timestamp
    );

    event MintTokenToWallet(
        address indexed sender,
        CollectionToken collectionToken,
        address indexed targetWallet,
        bytes data,
        uint256 timestamp
    );

    function mintTokenToProfile(
        CollectionToken memory collectionToken,
        uint256 profileId,
        bytes memory data
    ) external;

    function mintTokenToWallet(
        CollectionToken memory collectionToken,
        address targetWallet,
        bytes memory data
    ) external;

    function burnTokenFromProfile(
        CollectionToken memory collectionToken,
        uint256 profileId,
        bytes memory data
    ) external;
}