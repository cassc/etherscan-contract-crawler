// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import {IERC721Metadata} from "./IERC721.sol";

// these functions would be part of a spec
interface IERCNFTEnhancement is IERC721Metadata {
    function setUnderlyingToken(
        uint256 tokenId,
        address underlyingContract,
        uint256 underlyingTokenId
    )
        external;
    function getUnderlyingToken(uint256 tokenId)
        external
        view
        returns (address underlyingContract, uint256 underlyingTokenId);
}

// this includes custom functions that would not be part of the spec but our NFTEnhancement instance exposes
interface INFTEnhancement is IERCNFTEnhancement {
    /// returns the tokenURI of tokenId as if the underlying was set to the parameters
    function previewTokenURI(
        uint256 tokenId,
        address underlyingTokenContract,
        uint256 underlyingTokenId
    )
        external
        view
        returns (string memory tokenURI);
}