// SPDX-License-Identifier: MIT
pragma solidity >=0.8.16 <0.9.0;

import {ERC721A, ERC721ACommon} from "ethier/contracts/erc721/ERC721ACommon.sol";
import {BaseTokenURI} from "ethier/contracts/erc721/BaseTokenURI.sol";
import {DefaultOperatorFilterer} from "operator-filter-registry/DefaultOperatorFilterer.sol";
import {FeatureBlockable} from "./FeatureBlockable.sol";

/**
 * @notice
 */
contract RunEdMoonbirdsMiami is
    ERC721ACommon,
    BaseTokenURI,
    DefaultOperatorFilterer,
    FeatureBlockable
{
    // =========================================================================
    //                           Errors
    // =========================================================================

    error IllegalOperator();

    // =========================================================================
    //                           Types
    // =========================================================================

    /**
     * @notice The contract features that can be blocked.
     */
    enum BlockableFeature {
        Airdrop
    }

    // =========================================================================
    //                           Constructor
    // =========================================================================

    constructor(address payable royaltiesReceiver, string memory baseTokenURI_)
        ERC721ACommon(
            "Run Ed (Moonbirds Miami)",
            "RUN",
            royaltiesReceiver,
            1000
        )
        BaseTokenURI(baseTokenURI_)
    {}

    // =========================================================================
    //                           Airdrop
    // =========================================================================

    /**
     * @notice Airdrops tokens to a list of receivers.
     * @dev Can be locked by the contract owner.
     */
    function airdrop(address[] calldata receivers)
        external
        onlyUnblockedFeature(uint256(BlockableFeature.Airdrop))
        onlyOwner
    {
        for (uint256 idx = 0; idx < receivers.length; ) {
            _mint(receivers[idx], 1);
            unchecked {
                ++idx;
            }
        }
    }

    // =========================================================================
    //                           Steering
    // =========================================================================

    /**
     * @notice Interface to block a blockable contract feature.
     */
    function blockFeature(BlockableFeature feature) public onlyOwner {
        _blockFeature(uint256(feature));
    }

    // =========================================================================
    //                           Internals
    // =========================================================================

    /**
     * @dev Inheritance resolution.
     */
    function _baseURI()
        internal
        view
        virtual
        override(ERC721A, BaseTokenURI)
        returns (string memory)
    {
        return BaseTokenURI._baseURI();
    }

    // =========================================================================
    //                           Operator filtering
    // =========================================================================

    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        payable
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}