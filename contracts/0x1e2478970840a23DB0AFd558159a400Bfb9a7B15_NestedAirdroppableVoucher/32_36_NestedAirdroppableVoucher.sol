// SPDX-License-Identifier: MIT
// Copyright 2023 PROOF Holdings Inc
pragma solidity ^0.8.0;

import {IMoonbirds} from "moonbirds/IMoonbirds.sol";
import {OperatorFilterOS} from "ethier/erc721/OperatorFilterOS.sol";
import {
    ERC721A,
    ERC721ACommon,
    ERC721ACommonBaseTokenURI
} from "ethier/erc721/BaseTokenURI.sol";

import {ERC721VoucherBase} from "./common/ERC721Voucher.sol";
import {
    NestedAirdroppableToken,
    NestedAirdroppableOperatorFilteredToken
} from "./NestedAirdroppableToken.sol";

/**
 * @notice A voucher token that is airdropped to a subset of nested birds.
 */
contract NestedAirdroppableVoucher is
    NestedAirdroppableToken,
    ERC721VoucherBase
{
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
}

/**
 * @notice A voucher token that is airdropped to a subset of nested birds with
 * OSs operator-filtering.
 */
contract NestedAirdroppableOperatorFilteredVoucher is
    NestedAirdroppableOperatorFilteredToken,
    ERC721VoucherBase
{
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
        NestedAirdroppableOperatorFilteredToken(
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
        override(ERC721ACommonBaseTokenURI, NestedAirdroppableOperatorFilteredToken)
        returns (bool)
    {
        return NestedAirdroppableOperatorFilteredToken.supportsInterface(
            interfaceId
        ) || ERC721ACommonBaseTokenURI.supportsInterface(interfaceId);
    }

    function _baseURI()
        internal
        view
        virtual
        override(ERC721ACommonBaseTokenURI, NestedAirdroppableOperatorFilteredToken)
        returns (string memory)
    {
        return NestedAirdroppableOperatorFilteredToken._baseURI();
    }

    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override(ERC721A, NestedAirdroppableOperatorFilteredToken)
    {
        NestedAirdroppableOperatorFilteredToken.setApprovalForAll(
            operator, approved
        );
    }

    function approve(address operator, uint256 tokenId)
        public
        payable
        virtual
        override(ERC721A, NestedAirdroppableOperatorFilteredToken)
        onlyAllowedOperatorApproval(operator)
    {
        NestedAirdroppableOperatorFilteredToken.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId)
        public
        payable
        virtual
        override(ERC721A, NestedAirdroppableOperatorFilteredToken)
        onlyAllowedOperator(from)
    {
        NestedAirdroppableOperatorFilteredToken.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId)
        public
        payable
        virtual
        override(ERC721A, NestedAirdroppableOperatorFilteredToken)
        onlyAllowedOperator(from)
    {
        NestedAirdroppableOperatorFilteredToken.safeTransferFrom(
            from, to, tokenId
        );
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
        override(ERC721A, NestedAirdroppableOperatorFilteredToken)
        onlyAllowedOperator(from)
    {
        NestedAirdroppableOperatorFilteredToken.safeTransferFrom(
            from, to, tokenId, data
        );
    }
}