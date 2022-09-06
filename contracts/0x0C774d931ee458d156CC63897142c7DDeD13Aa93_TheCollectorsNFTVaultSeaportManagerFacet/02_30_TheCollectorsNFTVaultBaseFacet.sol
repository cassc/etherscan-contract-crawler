// SPDX-License-Identifier: UNLICENSED
// © 2022 The Collectors. All rights reserved.
pragma solidity ^0.8.13;

import "../Imports.sol";
import "../Interfaces.sol";
import "../LibDiamond.sol";
import {Order} from "../SeaportStructs.sol";

/*
    ████████╗██╗  ██╗███████╗     ██████╗ ██████╗ ██╗     ██╗     ███████╗ ██████╗████████╗ ██████╗ ██████╗ ███████╗
    ╚══██╔══╝██║  ██║██╔════╝    ██╔════╝██╔═══██╗██║     ██║     ██╔════╝██╔════╝╚══██╔══╝██╔═══██╗██╔══██╗██╔════╝
       ██║   ███████║█████╗      ██║     ██║   ██║██║     ██║     █████╗  ██║        ██║   ██║   ██║██████╔╝███████╗
       ██║   ██╔══██║██╔══╝      ██║     ██║   ██║██║     ██║     ██╔══╝  ██║        ██║   ██║   ██║██╔══██╗╚════██║
       ██║   ██║  ██║███████╗    ╚██████╗╚██████╔╝███████╗███████╗███████╗╚██████╗   ██║   ╚██████╔╝██║  ██║███████║
       ╚═╝   ╚═╝  ╚═╝╚══════╝     ╚═════╝ ╚═════╝ ╚══════╝╚══════╝╚══════╝ ╚═════╝   ╚═╝    ╚═════╝ ╚═╝  ╚═╝╚══════╝

    ███╗   ██╗███████╗████████╗    ██╗   ██╗ █████╗ ██╗   ██╗██╗  ████████╗
    ████╗  ██║██╔════╝╚══██╔══╝    ██║   ██║██╔══██╗██║   ██║██║  ╚══██╔══╝
    ██╔██╗ ██║█████╗     ██║       ██║   ██║███████║██║   ██║██║     ██║
    ██║╚██╗██║██╔══╝     ██║       ╚██╗ ██╔╝██╔══██║██║   ██║██║     ██║
    ██║ ╚████║██║        ██║        ╚████╔╝ ██║  ██║╚██████╔╝███████╗██║
    ╚═╝  ╚═══╝╚═╝        ╚═╝         ╚═══╝  ╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚═╝

    ██████╗  █████╗ ███████╗███████╗    ███████╗ █████╗  ██████╗███████╗████████╗
    ██╔══██╗██╔══██╗██╔════╝██╔════╝    ██╔════╝██╔══██╗██╔════╝██╔════╝╚══██╔══╝
    ██████╔╝███████║███████╗█████╗      █████╗  ███████║██║     █████╗     ██║
    ██╔══██╗██╔══██║╚════██║██╔══╝      ██╔══╝  ██╔══██║██║     ██╔══╝     ██║
    ██████╔╝██║  ██║███████║███████╗    ██║     ██║  ██║╚██████╗███████╗   ██║
    ╚═════╝ ╚═╝  ╚═╝╚══════╝╚══════╝    ╚═╝     ╚═╝  ╚═╝ ╚═════╝╚══════╝   ╚═╝
    @dev
    This is the base contract that the main contract and the assets manager are inheriting from
*/
abstract contract TheCollectorsNFTVaultBaseFacet is Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using Strings for uint256;
    using EnumerableSet for EnumerableSet.UintSet;

    // ==================== Events ====================

    event VaultCreated(uint256 indexed vaultId, address indexed collection, bool indexed privateVault);
    event ParticipantJoinedVault(uint256 indexed vaultId, address indexed participant);
    event NFTTokenWasSet(uint256 indexed vaultId, address indexed collection, uint256 indexed tokenId, uint256 maxPrice);
    event ListingPriceWasSet(uint256 indexed vaultId, address indexed collection, uint256 indexed tokenId, uint256 price);
    event VaultWasFunded(uint256 indexed vaultId, address indexed participant, uint256 indexed amount);
    event FundsWithdrawn(uint256 indexed vaultId, address indexed participant, uint256 indexed amount);
    event VaultTokenRedeemed(uint256 indexed vaultId, address indexed participant, uint256 indexed tokenId);
    event CollectorStaked(uint256 indexed vaultId, address indexed participant, uint256 indexed stakedCollectorTokenId);
    event CollectorUnstaked(uint256 indexed vaultId, address indexed participant, uint256 indexed stakedCollectorTokenId);
    event VaultTokenClaimed(uint256 indexed vaultId, address indexed participant, uint256 indexed tokenId);
    event NFTPurchased(uint256 indexed vaultId, address indexed collection, uint256 indexed tokenId, uint256 price);
    event NFTMigrated(uint256 indexed vaultId, address indexed collection, uint256 indexed tokenId, uint256 price);
    event NFTListedForSale(uint256 indexed vaultId, address indexed collection, uint256 indexed tokenId, uint256 price, Order order, uint256 counter);
    event NFTSellOrderCanceled(uint256 indexed vaultId, address indexed collection, uint256 indexed tokenId);
    event VotedForBuy(uint256 indexed vaultId, address indexed participant, bool indexed vote, address collection, uint256 tokenId);
    event VotedForSell(uint256 indexed vaultId, address indexed participant, bool indexed vote, address collection, uint256 tokenId, uint256 price);
    event VotedForCancel(uint256 indexed vaultId, address indexed participant, bool indexed vote, address collection, uint256 tokenId, uint256 price);
    event NFTSold(uint256 indexed vaultId, address indexed collection, uint256 indexed tokenId, uint256 price);
    event NFTWithdrawnToOwner(uint256 indexed vaultId, address indexed collection, uint256 indexed tokenId, address owner);
    event AcceptingOfferOfPriceWasSet(uint256 indexed vaultId, address indexed collection, uint256 indexed tokenId, uint256 price);
    event VotedForAcceptOffer(uint256 indexed vaultId, address indexed participant, bool indexed vote, address collection, uint256 tokenId, uint256 price);

    // ==================== Views ====================

    /*
        @dev
        A helper function to make sure there is a selling/cancelling consensus
    */
    function isVaultPassedSellOrCancelSellOrderConsensus(uint64 vaultId) public view returns (bool) {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        LibDiamond.Vault storage vault = _as.vaults[vaultId];
        uint256 votesPercentage;
        uint24 numberOfParticipants = _as.vaultsExtensions[vaultId].numberOfParticipants;
        for (uint256 i; i < numberOfParticipants;) {
            LibDiamond.Participant storage participant = _as.vaultParticipants[vault.id][i];
            // Either the participate voted yes for selling or the participate didn't vote at all
            // and the grace period was passed
            votesPercentage += _getParticipantSellOrCancelSellOrderVote(vault, participant)
            ? participant.ownership : 0;
            unchecked {
                ++i;
            }
        }
        // Need to check if equals too in case the sell consensus is 100%
        // Adding 1 wei since votesPercentage cannot be exactly 100%
        // Dividing by 1e6 to soften the threshold (but still very precise)
        return votesPercentage / 1e6 + 1 wei >= vault.sellOrCancelSellOrderConsensus / 1e6;
    }

    function isVaultSoldNFT(uint64 vaultId) public view returns (bool) {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        // Only vaults that already bought the NFT can sell it
        if (_as.vaults[vaultId].votingFor != LibDiamond.VoteFor.CancellingSellOrder
            && _as.vaults[vaultId].votingFor != LibDiamond.VoteFor.Selling) {
            return false;
        }
        if (_as.vaultsExtensions[vaultId].isERC1155) {
            return IERC1155(_as.vaults[vaultId].collection).balanceOf(_as.assetsHolders[vaultId], _as.vaults[vaultId].tokenId) == 0;
        } else {
            return IERC721(_as.vaults[vaultId].collection).ownerOf(_as.vaults[vaultId].tokenId) != _as.assetsHolders[vaultId];
        }
    }

    // ==================== Internals ====================

    /*
        @dev
        A helper function to verify that the vault is in buying state
    */
    function _requireVotingForBuyingOrWaitingForSettingTokenInfo(uint64 vaultId) internal view {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        require(_as.vaults[vaultId].votingFor == LibDiamond.VoteFor.Buying || _as.vaults[vaultId].votingFor == LibDiamond.VoteFor.WaitingToSetTokenInfo, "E1");
    }

    /*
        @dev
        A helper function to determine if a participant voted for selling or cancelling order
        or haven't voted yet but the grace period passed
    */
    function _getParticipantSellOrCancelSellOrderVote(
        LibDiamond.Vault storage vault,
        LibDiamond.Participant storage participant
    ) internal view returns (bool) {
        if (participant.voteDate >= vault.lastVoteDate) {
            return participant.vote;
        } else {
            return vault.endGracePeriodForSellingOrCancellingSellOrder != 0
            && block.timestamp > vault.endGracePeriodForSellingOrCancellingSellOrder;
        }
    }

    /*
        @dev
        A helper function to find out if a participant is part of a vault
    */
    function _isParticipantExists(uint64 vaultId, address participant) internal view returns (bool) {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        uint24 numberOfParticipants = _as.vaultsExtensions[vaultId].numberOfParticipants;
        for (uint256 i; i < numberOfParticipants;) {
            if (_as.vaultParticipants[vaultId][i].participant == participant) {
                return true;
            }
            unchecked {
                ++i;
            }
        }
        return false;
    }

    /*
        @dev
        A helper function to reset votes and grace period after listing for sale or cancelling a sell order
    */
    function _resetVotesAndGracePeriod(uint64 vaultId) internal {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        LibDiamond.Vault storage vault = _as.vaults[vaultId];
        vault.endGracePeriodForSellingOrCancellingSellOrder = 0;
        vault.lastVoteDate = uint48(block.timestamp);
    }

    /*
        @dev
        A helper function to calculate a participate or token id % in the vault.
        This function can be called before/after buying/selling the NFT
        Since tokenId cannot be 0 (as we are starting it from 1) it is ok to assume that if tokenId 0 was sent
        the method should return the participant %.
        In case address 0 was sent, the method will calculate the tokenId %.
    */
    function _getPercentage(uint64 vaultId, uint256 participantIndex, uint256 tokenId) internal view returns (uint256) {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        LibDiamond.VaultExtension storage vaultExtension = _as.vaultsExtensions[vaultId];
        uint256 totalPaid;
        uint256 participantsPaid;
        for (uint256 i; i < vaultExtension.numberOfParticipants; i++) {
            LibDiamond.Participant storage participant = _as.vaultParticipants[vaultId][i];
            totalPaid += participant.paid;
            if ((tokenId == 0 && i == participantIndex)
                || (tokenId != 0 && participant.partialNFTVaultTokenId == tokenId)) {
                // Found participant or token
                if (_as.vaults[vaultId].votingFor == LibDiamond.VoteFor.Selling || _as.vaults[vaultId].votingFor == LibDiamond.VoteFor.CancellingSellOrder) {
                    // Vault purchased the NFT
                    return participant.ownership;
                }
                participantsPaid = participant.paid;
            }
        }

        if (_as.vaults[vaultId].votingFor == LibDiamond.VoteFor.Selling || _as.vaults[vaultId].votingFor == LibDiamond.VoteFor.CancellingSellOrder) {
            // Vault purchased the NFT but participant or token that does not exist
            return 0;
        }

        // NFT wasn't purchased yet

        if (totalPaid > 0) {
            // Calculating % based on total paid
            return participantsPaid * 1e18 * 100 / totalPaid;
        } else {
            // No one paid, splitting equally
            return 1e18 * 100 / vaultExtension.numberOfParticipants;
        }
    }

    /*
        @dev
        A helper function to make sure there is a buying consensus and that the purchase price is
        lower than the total ETH paid and the max price to buy
    */
    function _requireBuyConsensusAndValidatePurchasePrice(uint64 vaultId, uint256 purchasePrice) internal view returns (uint256) {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        LibDiamond.VaultExtension storage vaultExtension = _as.vaultsExtensions[vaultId];
        LibDiamond.Vault storage vault = _as.vaults[vaultId];
        require(vault.votingFor == LibDiamond.VoteFor.Buying, "E1");
        uint256 totalPaid;
        uint256 votedPaid;
        for (uint256 i; i < vaultExtension.numberOfParticipants;) {
            LibDiamond.Participant storage participant = _as.vaultParticipants[vaultId][i];
            totalPaid += participant.paid;
            if (participant.voteDate >= vault.lastVoteDate && participant.vote) {
                votedPaid += participant.paid;
            }
            unchecked {
                ++i;
            }
        }
        require(purchasePrice <= totalPaid && purchasePrice <= vaultExtension.maxPriceToBuy, "E2");
        if (totalPaid == 0) {
            // Probably the vault is buying an NFT for 0
            return totalPaid;
        }
        // Need to check if equals too in case the buying consensus is 100%
        // Adding 1 wei since votesPercentage cannot be exactly 100%
        // Dividing by 1e6 to soften the threshold (but still very precise)
        uint256 votesPercentage = votedPaid * 1e18 * 100 / totalPaid;
        require(votesPercentage / 1e6 + 1 wei >= vault.buyConsensus / 1e6, "E3");
        return totalPaid;
    }

    /*
        @dev
        A helper function to validate whatever the vault is actually purchased the token and to calculate the final
        ownership of each participant
    */
    function _afterPurchaseNFT(uint64 vaultId, uint256 purchasePrice, bool withEvent, uint256 prevERC1155Amount, uint256 totalPaid) internal {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        LibDiamond.Vault storage vault = _as.vaults[vaultId];
        LibDiamond.VaultExtension storage vaultExtension = _as.vaultsExtensions[vaultId];
        // Cannot be below zero because otherwise the buying would have failed
        uint256 leftovers = totalPaid - purchasePrice;
        for (uint256 i; i < vaultExtension.numberOfParticipants;) {
            LibDiamond.Participant storage participant = _as.vaultParticipants[vaultId][i];
            if (totalPaid > 0) {
                participant.leftovers = uint128(leftovers * uint256(participant.paid) / totalPaid);
            } else {
                // If totalPaid = 0 then returning all what the participant paid
                // This can happen if everyone withdraws their funds after voting yes
                participant.leftovers = participant.paid;
            }
            if (totalPaid > 0) {
                // Calculating % based on total paid
                participant.ownership = uint128(uint256(participant.paid) * 1e18 * 100 / totalPaid);
            } else {
                // No one paid, splitting equally
                // This can happen if everyone withdraws their funds after voting yes
                participant.ownership = uint128(1e18 * 100 / vaultExtension.numberOfParticipants);
            }
            participant.paid = participant.paid - participant.leftovers;

            unchecked {
                ++i;
            }
        }

        if (vaultExtension.isERC1155) {
            // If it was == 1, then it was open to attacks
            require(IERC1155(vault.collection).balanceOf(_as.assetsHolders[vaultId], vault.tokenId) > prevERC1155Amount, "E4");
        } else {
            require(IERC721(vault.collection).ownerOf(vault.tokenId) == _as.assetsHolders[vaultId], "E4");
        }
        // Resetting vote so the participate will be able to vote for setListingPrice
        vault.lastVoteDate = uint48(block.timestamp);
        // Next vote will be for selling
        vault.votingFor = LibDiamond.VoteFor.Selling;
        // Since participate.paid is updating and re-calculated after buying the NFT the sum of all participants paid
        // can be a little different from the actual purchase price, however, it should never be more than purchasedFor
        // in order to not get insufficient funds exception
        vault.purchasedFor = uint128(purchasePrice);
        // Adding vault to collection's list
        _as.collectionsVaults[vault.collection].push(vaultId);
        if (withEvent) {
            emit NFTPurchased(vault.id, vault.collection, vault.tokenId, purchasePrice);
        }
    }

}