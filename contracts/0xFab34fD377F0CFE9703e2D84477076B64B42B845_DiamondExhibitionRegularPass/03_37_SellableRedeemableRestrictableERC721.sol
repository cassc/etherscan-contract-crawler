// SPDX-License-Identifier: MIT
// Copyright 2023 PROOF Holdings Inc
pragma solidity ^0.8.15;

import {ERC721A, ERC721ACommon, BaseTokenURI, ERC721ACommonBaseTokenURI} from "ethier/erc721/BaseTokenURI.sol";
import {OperatorFilterOS} from "ethier/erc721/OperatorFilterOS.sol";

import {
    TransferRestrictedRedeemableERC721ACommon,
    TransferRestriction
} from "proof/redemption/voucher/TransferRestrictedRedeemableERC721ACommon.sol";
import {SellableERC721ACommon} from "proof/sellers/sellable/SellableERC721ACommon.sol";

/**
 * @notice A redeemable and sellable ERC721 token with operator filtering and transfer restrictions.
 * @dev The contract name should be sung to the tune of "Modern Major-General"
 */
abstract contract SellableRedeemableRestrictableERC721 is
    ERC721ACommonBaseTokenURI,
    OperatorFilterOS,
    SellableERC721ACommon,
    TransferRestrictedRedeemableERC721ACommon
{
    // =================================================================================================================
    //                          Inheritance Resolution
    // =================================================================================================================

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721ACommon, ERC721ACommonBaseTokenURI, SellableERC721ACommon, TransferRestrictedRedeemableERC721ACommon)
        returns (bool)
    {
        return TransferRestrictedRedeemableERC721ACommon.supportsInterface(interfaceId)
            || SellableERC721ACommon.supportsInterface(interfaceId)
            || ERC721ACommonBaseTokenURI.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfers(address from, address to, uint256 startTokenId, uint256 quantity)
        internal
        virtual
        override(ERC721ACommon, TransferRestrictedRedeemableERC721ACommon)
    {
        TransferRestrictedRedeemableERC721ACommon._beforeTokenTransfers(from, to, startTokenId, quantity);
    }

    function _baseURI() internal view virtual override(ERC721A, ERC721ACommonBaseTokenURI) returns (string memory) {
        return ERC721ACommonBaseTokenURI._baseURI();
    }

    function setApprovalForAll(address operator, bool approved) public virtual override(ERC721A, OperatorFilterOS) {
        OperatorFilterOS.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable virtual override(ERC721A, OperatorFilterOS) {
        OperatorFilterOS.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId)
        public
        payable
        virtual
        override(ERC721A, OperatorFilterOS)
    {
        OperatorFilterOS.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId)
        public
        payable
        virtual
        override(ERC721A, OperatorFilterOS)
    {
        OperatorFilterOS.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
        virtual
        override(ERC721A, OperatorFilterOS)
    {
        OperatorFilterOS.safeTransferFrom(from, to, tokenId, data);
    }
}