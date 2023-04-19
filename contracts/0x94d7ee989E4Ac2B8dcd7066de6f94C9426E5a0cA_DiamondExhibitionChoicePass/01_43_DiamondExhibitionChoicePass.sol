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
import {RoleGatedFreeOfCharge} from "proof/sellers/presets/RoleGatedFreeOfCharge.sol";

/**
 * @title Diamond Exhibition: Choice Pass
 * @notice A redeemable token airdropped to all day-1 nested Moonbirds that allows mints with preferences from the diamond exhibition.
 */
contract DiamondExhibitionChoicePass is
    ERC721ACommonBaseTokenURI,
    OperatorFilterOS,
    SellableERC721ACommon,
    TransferRestrictedRedeemableERC721ACommon
{
    /**
     * @notice The seller handling the airdrop.
     */
    RoleGatedFreeOfCharge public airdropper;

    constructor(address admin, address steerer, address payable secondaryReceiver, uint64 numDayOneBirds)
        ERC721ACommon(admin, steerer, "Diamond Exhibition: Day One Pass", "DAY1PASS", secondaryReceiver, 500)
        BaseTokenURI("https://metadata.proof.xyz/diamond-exhibition-pass/day-one/")
    {
        airdropper = new RoleGatedFreeOfCharge(admin , steerer, this, numDayOneBirds);
        _grantRole(AUTHORISED_SELLER_ROLE, address(airdropper));
    }

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