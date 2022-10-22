// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "../../access/ownable/OwnableInternal.sol";

import "./RoyaltyStorage.sol";
import "./RoyaltyInternal.sol";
import "./IRoyaltyAdmin.sol";

/**
 * @title ERC2981 - Royalty - Admin - Ownable
 * @notice Allow contract owner to manage token royalties based on EIP-2981 standard.
 *
 * @custom:type eip-2535-facet
 * @custom:category Finance
 * @custom:peer-dependencies IRoyalty IEIP2981
 * @custom:provides-interfaces IRoyaltyAdmin
 */
contract RoyaltyOwnable is IRoyaltyAdmin, RoyaltyInternal, OwnableInternal {
    using RoyaltyStorage for RoyaltyStorage.Layout;

    function setTokenRoyalties(TokenRoyaltyConfig[] calldata royalties) external override onlyOwner {
        _setTokenRoyalties(royalties);
    }

    function setDefaultRoyalty(TokenRoyalty calldata royalty) external override onlyOwner {
        _setDefaultRoyalty(royalty);
    }
}