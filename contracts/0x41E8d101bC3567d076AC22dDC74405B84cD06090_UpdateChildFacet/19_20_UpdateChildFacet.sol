// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import {OwnableInternal} from "@solidstate/contracts/access/ownable/OwnableInternal.sol";

import {ERC721BaseInternal} from "./solidstate/ERC721BaseInternal.sol";
import {ScapesERC721MetadataStorage} from "./ScapesERC721MetadataStorage.sol";
import {IChild} from "./IChild.sol";
import {ScapesMerge} from "../metadata/ScapesMerge.sol";

import {ScapesMarketplaceStorage} from "./marketplace/ScapesMarketplaceStorage.sol";
import {IERC721MarketplaceInternal} from "./marketplace/IERC721MarketplaceInternal.sol";

/// @title UpdateChildFacet
/// @author akuti.eth | scapes.eth
/// @dev The facet is used to update the child collection of Scapes.
contract UpdateChildFacet is OwnableInternal {
    function batchBurn(address[] memory tokenOwners, uint256 offset)
        external
        onlyOwner
    {
        IChild child = IChild(ScapesERC721MetadataStorage.layout().scapeBound);
        uint256 length = tokenOwners.length;

        unchecked {
            for (uint256 i = 0; i < length; ) {
                child.update(tokenOwners[i], address(0), offset);
                i++;
                offset++;
            }
        }
    }

    function manualUpdate(
        address from,
        address to,
        uint256 tokenId
    ) external onlyOwner {
        IChild(ScapesERC721MetadataStorage.layout().scapeBound).update(
            from,
            to,
            tokenId
        );
    }

    function updateChildAddress(address child) external onlyOwner {
        ScapesERC721MetadataStorage.layout().scapeBound = child;
    }

    function getChildAddress() external view returns (address) {
        return ScapesERC721MetadataStorage.layout().scapeBound;
    }
}