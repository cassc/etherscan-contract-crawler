// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { ERC721AUpgradeableInternal } from "./../ERC721AUpgradeableContracts/ERC721AUpgradeableInternal.sol";
import { LibDiamond } from "../libraries/LibDiamond.sol";
import { LibRoosting } from "../libraries/LibRoosting.sol";
import { LibOwls } from "../libraries/LibOwls.sol";
import { RoostingFacet } from "../facets/RoostingFacet.sol";

contract MintFacet is ERC721AUpgradeableInternal {
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);
    event RoostingClaimed(uint256[] orderedRoostedGroups, LibRoosting.RoostingState roostingClaimed);

    error ContractNotAllowedToMint();
    error NoRoostingGroup();
    error OneOrMoreOwlsNotRoosted();
    error NotOwnerOfAllOwlsRoosted();
    error PostRoostingHasNotStarted();
    error InvalidRoostingGroup();
    error RoostingGroupAlreadyClaimed();

    /// @notice Mint 1 or more NFTs consecutively based on number of roosted groups held by msg.sender
    // https://eips.ethereum.org/EIPS/eip-4906
    /// @param roostedGroupIndexes An array of the roosted group indexes to claim that are 1-based indexes
    function mint(uint32[] calldata roostedGroupIndexes) external payable {
        LibRoosting.RoostingStorage storage rs = LibRoosting.roostingStorage();

        if (msg.sender != tx.origin) {
            revert ContractNotAllowedToMint();
        }

        if (rs.roostingCycle != LibRoosting.RoostingCycle.Postroosting) {
            revert PostRoostingHasNotStarted();
        }

        uint256 tokenId = _nextTokenId();
        uint16 amtOfClaimableNFTs;
        IERC721 owlsContract = IERC721(LibOwls.owlsStorage().owlsContract);

        for (uint256 i = 0; i < roostedGroupIndexes.length;) {            
            LibRoosting.RoostingGroupStorage storage rgs = LibRoosting.roostingGroupStorage(rs.currentRoostingCycle, roostedGroupIndexes[i]);
            if(rgs.owlsRoosted == 0) {
                revert InvalidRoostingGroup();
            }
            if (rgs.roostingState != LibRoosting.RoostingState.Roosted) {
                revert RoostingGroupAlreadyClaimed();
            }
            uint256[] memory roostedOwlIds = LibRoosting.roostingGroupOwls(rs.currentRoostingCycle, roostedGroupIndexes[i]);

            for (uint256 j = 0; j < roostedOwlIds.length;) {
                if (owlsContract.ownerOf(roostedOwlIds[j]) != msg.sender) {
                    revert NotOwnerOfAllOwlsRoosted();
                }
                unchecked {
                    ++j;
                }
            }
            
            rgs.roostingState = LibRoosting.RoostingState.RoostingClaimed;
            emit RoostingClaimed(roostedOwlIds, LibRoosting.RoostingState.RoostingClaimed);

            unchecked {
                ++amtOfClaimableNFTs;
                ++i;
            }
        }

        _mint(msg.sender, amtOfClaimableNFTs);

        if (tokenId != 0) emit BatchMetadataUpdate(0, (tokenId + amtOfClaimableNFTs) - 1);
    }
}