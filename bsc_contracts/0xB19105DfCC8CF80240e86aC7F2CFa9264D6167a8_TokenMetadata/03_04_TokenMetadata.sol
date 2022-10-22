// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/Strings.sol";

import "./ITokenMetadata.sol";
import "./TokenMetadataStorage.sol";

/**
 * @title NFT Token Metadata
 * @notice Provides common functions for various NFT metadata standards. This extension supports base URI, per-token URI, and a fallback URI. You can also freeze URIs until a certain token ID.
 *
 * @custom:type eip-2535-facet
 * @custom:category NFTs
 * @custom:provides-interfaces ITokenMetadata
 */
contract TokenMetadata is ITokenMetadata {
    function baseURI() external view virtual returns (string memory) {
        return TokenMetadataStorage.layout().baseURI;
    }

    function fallbackURI() external view virtual returns (string memory) {
        return TokenMetadataStorage.layout().fallbackURI;
    }

    function uriSuffix() external view virtual returns (string memory) {
        return TokenMetadataStorage.layout().uriSuffix;
    }

    function baseURILocked() external view virtual returns (bool) {
        return TokenMetadataStorage.layout().baseURILocked;
    }

    function fallbackURILocked() external view virtual returns (bool) {
        return TokenMetadataStorage.layout().fallbackURILocked;
    }

    function uriSuffixLocked() external view virtual returns (bool) {
        return TokenMetadataStorage.layout().uriSuffixLocked;
    }

    function lastLockedTokenId() external view virtual returns (uint256) {
        return TokenMetadataStorage.layout().lastLockedTokenId;
    }
}