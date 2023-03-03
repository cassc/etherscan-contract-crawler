// SPDX-License-Identifier: MIT
// Copyright 2023 PROOF Holdings Inc
pragma solidity ^0.8.0;

import {IMoonbirds} from "moonbirds/IMoonbirds.sol";
import {OperatorFilterOS} from "ethier/erc721/OperatorFilterOS.sol";
import {
    ERC721A,
    ERC721ACommon,
    BaseTokenURI,
    ERC721ACommonBaseTokenURI
} from "ethier/erc721/BaseTokenURI.sol";

import {ERC721VoucherBase} from "./common/ERC721Voucher.sol";
import {NestedAirdroppableBase} from "./common/NestedAirdroppableBase.sol";

/**
 * @notice A token token that is airdropped to a subset of nested birds.
 */
abstract contract NestedAirdroppableTokenBase is
    ERC721ACommonBaseTokenURI,
    NestedAirdroppableBase
{
    // =========================================================================
    //                           Airdrop
    // =========================================================================

    /**
     * @notice Performs airdrops to the owners of a list of nested moonbirds.
     * @dev If a moonbird is not nested it is skipped.
     */
    function airdrop(uint256[] calldata birbIds)
        external
        onlyRole(DEFAULT_STEERING_ROLE)
    {
        _airdrop(birbIds);
    }

    // =========================================================================
    //                           Internals
    // =========================================================================

    /**
     * @notice Each airdrop mints a voucher to the owner of the moonbird.
     */
    function _doAirdrop(address receiver, uint256) internal virtual override {
        _mint(receiver, 1);
    }
}

/**
 * @notice A token token that is airdropped to a subset of nested birds.
 */
contract NestedAirdroppableToken is NestedAirdroppableTokenBase {
    // =========================================================================
    //                           Constructor
    // =========================================================================
    constructor(
        address admin,
        address steerer,
        string memory name_,
        string memory symbol_,
        address payable royaltiesReceiver_,
        uint96 royaltyBasisPoints_,
        string memory baseTokenURI_,
        IMoonbirds moonbirds,
        uint256 maxNumAirdrops
    )
        ERC721ACommon(
            admin,
            steerer,
            name_,
            symbol_,
            royaltiesReceiver_,
            royaltyBasisPoints_
        )
        BaseTokenURI(baseTokenURI_)
        NestedAirdroppableBase(moonbirds, maxNumAirdrops)
    {}
}

/**
 * @notice A token that is airdropped to a subset of nested birds with OSs
 * operator-filtering.
 */
contract NestedAirdroppableOperatorFilteredToken is
    NestedAirdroppableToken,
    OperatorFilterOS
{
    // =========================================================================
    //                              Constructor
    // =========================================================================
    constructor(
        address admin,
        address steerer,
        string memory name_,
        string memory symbol_,
        address payable royaltiesReceiver_,
        uint96 royaltyBasisPoints_,
        string memory baseTokenURI_,
        IMoonbirds moonbirds,
        uint256 maxNumAirdrops
    )
        NestedAirdroppableToken(
            admin,
            steerer,
            name_,
            symbol_,
            royaltiesReceiver_,
            royaltyBasisPoints_,
            baseTokenURI_,
            moonbirds,
            maxNumAirdrops
        )
    {}

    // =========================================================================
    //                           Inheritance Resolution
    // =========================================================================

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721ACommon, ERC721ACommonBaseTokenURI)
        returns (bool)
    {
        return ERC721ACommonBaseTokenURI.supportsInterface(interfaceId);
    }

    function _baseURI()
        internal
        view
        virtual
        override(ERC721A, ERC721ACommonBaseTokenURI)
        returns (string memory)
    {
        return ERC721ACommonBaseTokenURI._baseURI();
    }

    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override(ERC721A, OperatorFilterOS)
    {
        OperatorFilterOS.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        payable
        virtual
        override(ERC721A, OperatorFilterOS)
        onlyAllowedOperatorApproval(operator)
    {
        OperatorFilterOS.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId)
        public
        payable
        virtual
        override(ERC721A, OperatorFilterOS)
        onlyAllowedOperator(from)
    {
        OperatorFilterOS.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId)
        public
        payable
        virtual
        override(ERC721A, OperatorFilterOS)
        onlyAllowedOperator(from)
    {
        OperatorFilterOS.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    )
        public
        payable
        virtual
        override(ERC721A, OperatorFilterOS)
        onlyAllowedOperator(from)
    {
        OperatorFilterOS.safeTransferFrom(from, to, tokenId, data);
    }
}