// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {PassiveStaking} from "./PassiveStaking.sol";
import {IERC4906} from "../extensions/IERC4906.sol";
import {IERC721A} from "erc721a/contracts/IERC721A.sol";

abstract contract TieredMetadata is IERC721A, IERC4906, PassiveStaking {
    // Tier configuration
    struct Tier {
        uint256 points;
        string overrideBaseUri;
    }

    // Tier metadata and configuration
    Tier[] private _tiers;

    bool public isRevealed = false;
    uint256 private _maxTier;
    string private _defaultBaseURI;
    string private _unrevealedBaseURI;

    function tierRequirement(uint256 tierIndex) public view returns (uint256) {
        return _tiers[tierIndex].points;
    }

    function maxTiers() public view returns (uint256) {
        return _maxTier;
    }

    function tier(uint256 tokenId) public view virtual returns (uint256) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        uint256 points = earned(tokenId);
        uint256 index = _maxTier;

        do {
            if (points >= _tiers[index].points) return index;
            unchecked {
                index == index--;
            }
        } while (index > 0);

        return 0;
    }

    function _baseURI(uint256 tokenId) internal view virtual returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        if (isRevealed == false) return _unrevealedBaseURI;

        uint256 tokenTier = tier(tokenId);

        if (bytes(_tiers[tokenTier].overrideBaseUri).length > 0) {
            return _tiers[tokenTier].overrideBaseUri;
        }
        return string(abi.encodePacked(_defaultBaseURI, _toString(tokenTier), "/"));
    }

    function _tokenURI(uint256 tokenId) internal view virtual returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI(tokenId);

        if (isRevealed == false) return baseURI;
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId))) : "";
    }

    // ADMIN FUNCTIONS
    function _setRevealed() internal {
        isRevealed = true;
    }

    function _setUnrevealedBaseURI(string memory baseUri_) internal {
        _unrevealedBaseURI = baseUri_;
        emit BatchMetadataUpdate(_startTokenId(), _totalMinted());
    }

    function _setBaseURI(string memory baseUri_) internal {
        _defaultBaseURI = baseUri_;
        emit BatchMetadataUpdate(_startTokenId(), _totalMinted());
    }

    function _setTierBaseURI(uint256 tier_, string memory baseUri_) internal {
        _tiers[tier_].overrideBaseUri = baseUri_;
        emit BatchMetadataUpdate(_startTokenId(), _totalMinted());
    }

    function _addTier(Tier memory tier_) internal {
        _tiers.push(tier_);
        _maxTier = _tiers.length - 1;
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override {
        if (from == address(0)) return;
        if (_tiers.length > 0) {
            // If token id has reached any tier, issue the tier's base points
            uint256 currTier = tier(startTokenId);
            _issue(startTokenId, _tiers[currTier].points);
        }

        PassiveStaking._beforeTokenTransfers(from, to, startTokenId, quantity);
    }
}

error URIQueryForNonexistentToken();