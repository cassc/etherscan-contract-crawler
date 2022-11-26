// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "./ITokenMetadataInternal.sol";
import "./TokenMetadataStorage.sol";

abstract contract TokenMetadataAdminInternal is ITokenMetadataInternal {
    function _setBaseURI(string memory baseURI) internal virtual {
        require(!TokenMetadataStorage.layout().baseURILocked, "Metadata: baseURI locked");
        TokenMetadataStorage.layout().baseURI = baseURI;
    }

    function _setFallbackURI(string memory baseURI) internal virtual {
        require(!TokenMetadataStorage.layout().fallbackURILocked, "Metadata: fallbackURI locked");
        TokenMetadataStorage.layout().fallbackURI = baseURI;
    }

    function _setURI(uint256 tokenId, string memory tokenURI) internal virtual {
        require(tokenId >= TokenMetadataStorage.layout().lastUnlockedTokenId, "Metadata: tokenURI locked");
        TokenMetadataStorage.layout().tokenURIs[tokenId] = tokenURI;
        emit URI(tokenURI, tokenId);
    }

    function _setURISuffix(string memory uriSuffix) internal virtual {
        require(!TokenMetadataStorage.layout().uriSuffixLocked, "Metadata: uriSuffix locked");
        TokenMetadataStorage.layout().uriSuffix = uriSuffix;
    }

    function _lockBaseURI() internal virtual {
        TokenMetadataStorage.layout().baseURILocked = true;
    }

    function _lockFallbackURI() internal virtual {
        TokenMetadataStorage.layout().fallbackURILocked = true;
    }

    function _lockURIUntil(uint256 tokenId) internal virtual {
        TokenMetadataStorage.layout().lastUnlockedTokenId = tokenId;
    }

    function _lockURISuffix() internal virtual {
        TokenMetadataStorage.layout().uriSuffixLocked = true;
    }
}