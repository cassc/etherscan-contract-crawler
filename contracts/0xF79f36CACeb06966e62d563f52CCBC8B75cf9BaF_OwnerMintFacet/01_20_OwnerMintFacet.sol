// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Modifiers} from "../libraries/Modifiers.sol";
import {Shared} from "../libraries/Shared.sol";
import {Edition} from "../libraries/LibAppStorage.sol";
import {ERC721ALib} from "../libraries/ERC721ALib.sol";

contract OwnerMintFacet is Modifiers {
    error EditionSoldOut();

    // Free mint for owners editions
    function ownerMintEditions(
        address to,
        uint256 quantity,
        uint256 editionIndex
    ) external payable onlyOwner {
        if (!s.editionsEnabled) revert Shared.EditionsDisabled();
        uint256 startToken = s.currentIndex;

        // Need to use storage to increment at end
        Edition storage _edition = s.editionsByIndex[editionIndex];

        // Check if edition is unlimited or if it would exceed supply
        unchecked {
            if (
                _edition.maxSupply > 0 &&
                (_edition.totalSupply + quantity) > _edition.maxSupply
            ) {
                revert EditionSoldOut();
            }
        }

        ERC721ALib._mint(to, quantity);

        // Set token edition
        // Next token ID is s.currentIndex;
        ERC721ALib._setExtraDataAt(startToken, uint24(editionIndex));

        // Increment the edition supply
        _edition.totalSupply += quantity;
    }
}