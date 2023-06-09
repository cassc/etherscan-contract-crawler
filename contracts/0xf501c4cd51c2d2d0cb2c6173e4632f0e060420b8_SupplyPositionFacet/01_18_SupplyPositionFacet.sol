// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import {DiamondERC721} from "./SupplyPositionLogic/DiamondERC721.sol";
import {ERC721InvalidTokenId} from "./DataStructure/ERC721Errors.sol";
import {SupplyPosition, Provision} from "./DataStructure/Storage.sol";
import {supplyPositionStorage, supplyPositionMetadataStorage} from "./DataStructure/Global.sol";
import {IOwnershipFacet} from "./interface/IOwnershipFacet.sol";
import {CallerIsNotOwner} from "./DataStructure/Errors.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

/// @notice NFT collection facet for transferable tradable non fungible supply positions
contract SupplyPositionFacet is DiamondERC721 {
    // constructor equivalent is in the Initializer contract
    using Strings for uint256;

    /// @notice get metadata on provision linked to the supply position
    /// @param tokenId token identifier of the supply position
    /// @return provision metadata
    function position(uint256 tokenId) external view returns (Provision memory) {
        SupplyPosition storage sp = supplyPositionStorage();

        if (tokenId > sp.totalSupply) {
            revert ERC721InvalidTokenId();
        }

        return sp.provision[tokenId];
    }

    /// @notice total number of supply positions ever minted (counting burned ones)
    /// @return totalSupply the number
    function totalSupply() external view returns (uint256) {
        return supplyPositionStorage().totalSupply;
    }

    /// @notice get the token URI for a given token identifier
    /// @param tokenId token identifier of the supply position
    /// @return URI univeral resource identifier of the token metadata
    function tokenURI(uint256 tokenId) external view returns (string memory) {
        _ownerOf(tokenId); // revert on invalid tokenId
        return string(abi.encodePacked(supplyPositionMetadataStorage().baseUri, tokenId.toString()));
    }
}