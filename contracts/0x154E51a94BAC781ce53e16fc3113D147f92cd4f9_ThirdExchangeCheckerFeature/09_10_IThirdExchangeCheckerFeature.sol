/// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "./interfaces/IConduitController.sol";
import "./interfaces/ISeaport.sol";
import "./interfaces/ITransferSelectorNFT.sol";
import "./interfaces/ILooksRare.sol";
import "./interfaces/IX2y2.sol";


interface IThirdExchangeCheckerFeature {

    struct SeaportCheckInfo {
        address conduit;
        bool conduitExists;
        address erc721Owner;
        bool isApprovedForAll; // erc721.isApprovedForAll or erc1155.isApprovedForAll
        address erc721ApprovedAccount; // erc721.getApproved(tokenId)
        uint256 erc1155Balance;
        bool isValidated;
        bool isCancelled;
        uint256 totalFilled;
        uint256 totalSize;
    }

    struct LooksRareCheckInfo {
        address transferManager;
        address erc721Owner;
        bool isApprovedForAll; // erc721.isApprovedForAll or erc1155.isApprovedForAll
        address erc721ApprovedAccount; // erc721.getApproved(tokenId)
        uint256 erc1155Balance;
        bool isExecutedOrCancelled;
    }

    struct X2y2CheckInfo {
        address erc721Owner;
        bool isApprovedForAll; // erc721.isApprovedForAll
        address erc721ApprovedAccount; // erc721.getApproved(tokenId)
        IX2y2.InvStatus status;
    }

    /// @param itemType itemType 0: ERC721, 1: ERC1155
    function getSeaportCheckInfoEx(address account, uint8 itemType, address nft, uint256 tokenId, bytes32 conduitKey, bytes32 orderHash)
        external
        view
        returns (SeaportCheckInfo memory info);

    function getSeaportCheckInfo(address account, address nft, uint256 tokenId, bytes32 conduitKey, bytes32 orderHash)
        external
        view
        returns (SeaportCheckInfo memory info);

    /// @param itemType itemType 0: ERC721, 1: ERC1155
    function getLooksRareCheckInfoEx(address account, uint8 itemType, address nft, uint256 tokenId, uint256 accountNonce)
        external
        view
        returns (LooksRareCheckInfo memory info);

    function getLooksRareCheckInfo(address account, address nft, uint256 tokenId, uint256 accountNonce)
        external
        view
        returns (LooksRareCheckInfo memory info);

    function getX2y2CheckInfo(address account, address nft, uint256 tokenId, bytes32 orderHash, address executionDelegate)
        external
        view
        returns (X2y2CheckInfo memory info);
}