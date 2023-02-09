// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;
import "../libraries/BitMaps/BitMaps.sol";
import "../platform/royalties/IRoyaltiesRegistry.sol";

interface IERC721Events {
    event EditionCreated(
        address indexed contractAddress,
        uint256 editionId,
        uint24 maxSupply,
        string baseURI,
        uint24 contractMintPrice,
        bool editionned

    );
    event EditionUpdated(
        address indexed contractAddress,
        uint256 editionId,
        uint256 maxSupply,
        string baseURI
    );
    
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

}