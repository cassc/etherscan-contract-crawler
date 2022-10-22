// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@manifoldxyz/royalty-registry-solidity/contracts/overrides/IRoyaltyOverride.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "./IRoyaltyInternal.sol";
import "./RoyaltyStorage.sol";

/**
 * @title Royalty standard functionality base on EIP-2981 (derived from Manifold.xyz contracts to adopt Diamond architecture)
 */
abstract contract RoyaltyInternal is IRoyaltyInternal {
    using RoyaltyStorage for RoyaltyStorage.Layout;
    using EnumerableSet for EnumerableSet.UintSet;

    /**
     * @dev Sets token royalties. When you override this in the implementation contract
     * ensure that you access restrict it to the contract owner or admin
     */
    function _setTokenRoyalties(TokenRoyaltyConfig[] memory royaltyConfigs) internal virtual {
        RoyaltyStorage.Layout storage l = RoyaltyStorage.layout();

        for (uint256 i = 0; i < royaltyConfigs.length; i++) {
            TokenRoyaltyConfig memory royaltyConfig = royaltyConfigs[i];

            require(royaltyConfig.bps < 10000, "Invalid bps");

            if (royaltyConfig.recipient == address(0)) {
                delete l.tokenRoyalties[royaltyConfig.tokenId];
                l.tokensWithRoyalties.remove(royaltyConfig.tokenId);

                emit TokenRoyaltyRemoved(royaltyConfig.tokenId);
            } else {
                l.tokenRoyalties[royaltyConfig.tokenId] = TokenRoyalty(royaltyConfig.recipient, royaltyConfig.bps);
                l.tokensWithRoyalties.add(royaltyConfig.tokenId);

                emit TokenRoyaltySet(royaltyConfig.tokenId, royaltyConfig.recipient, royaltyConfig.bps);
            }
        }
    }

    /**
     * @dev Sets default royalty. When you override this in the implementation contract
     * ensure that you access restrict it to the contract owner or admin
     */
    function _setDefaultRoyalty(TokenRoyalty memory royalty) internal virtual {
        require(royalty.bps < 10000, "Invalid bps");

        RoyaltyStorage.layout().defaultRoyalty = TokenRoyalty(royalty.recipient, royalty.bps);

        emit DefaultRoyaltySet(royalty.recipient, royalty.bps);
    }

    /**
     * @dev See {IEIP2981RoyaltyOverride-getTokenRoyaltiesCount}.
     */
    function _getTokenRoyaltiesCount() internal view virtual returns (uint256) {
        return RoyaltyStorage.layout().tokensWithRoyalties.length();
    }

    /**
     * @dev See {IEIP2981RoyaltyOverride-getTokenRoyaltyByIndex}.
     */
    function _getTokenRoyaltyByIndex(uint256 index) internal view virtual returns (TokenRoyaltyConfig memory) {
        RoyaltyStorage.Layout storage l = RoyaltyStorage.layout();

        uint256 tokenId = l.tokensWithRoyalties.at(index);
        TokenRoyalty memory royalty = l.tokenRoyalties[tokenId];

        return TokenRoyaltyConfig(tokenId, royalty.recipient, royalty.bps);
    }

    /**
     * @dev See {IEIP2981RoyaltyOverride-royaltyInfo}.
     */
    function _royaltyInfo(uint256 tokenId, uint256 value) internal view virtual returns (address, uint256) {
        RoyaltyStorage.Layout storage l = RoyaltyStorage.layout();

        if (l.tokenRoyalties[tokenId].recipient != address(0)) {
            return (l.tokenRoyalties[tokenId].recipient, (value * l.tokenRoyalties[tokenId].bps) / 10000);
        }

        if (l.defaultRoyalty.recipient != address(0) && l.defaultRoyalty.bps != 0) {
            return (l.defaultRoyalty.recipient, (value * l.defaultRoyalty.bps) / 10000);
        }

        return (address(0), 0);
    }
}