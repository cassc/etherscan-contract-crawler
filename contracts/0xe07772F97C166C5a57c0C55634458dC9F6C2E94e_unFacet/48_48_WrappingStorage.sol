// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

library WrappingStorage {
    bytes32 internal constant STORAGE_SLOT = keccak256("untrading.unDiamond.NFT.facet.ERC721.wrapping.storage");

    struct Wrapped {
        address underlyingTokenAddress;
        uint256 underlyingTokenId;
        bool isWrapped;
    }

    struct Layout {
        mapping(uint256 => Wrapped) _wrappedTokens; // Mapping that represents a tokenId's wrapping information
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}