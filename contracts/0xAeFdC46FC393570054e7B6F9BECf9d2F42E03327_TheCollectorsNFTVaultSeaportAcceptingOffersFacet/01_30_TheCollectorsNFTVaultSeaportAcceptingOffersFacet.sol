// SPDX-License-Identifier: UNLICENSED
// © 2022 The Collectors. All rights reserved.
pragma solidity ^0.8.13;

import "./TheCollectorsNFTVaultBaseFacet.sol";
import "../TheCollectorsNFTVaultSeaportAssetsHolderImpl.sol";
import {BasicOrderParameters, OrderComponents, Order, Fulfillment} from "../SeaportStructs.sol";
import {ItemType} from "../SeaportEnums.sol";
import "../TheCollectorsNFTVaultSeaportAssetsHolderProxy.sol";

/*
    ████████╗██╗  ██╗███████╗     ██████╗ ██████╗ ██╗     ██╗     ███████╗ ██████╗████████╗ ██████╗ ██████╗ ███████╗
    ╚══██╔══╝██║  ██║██╔════╝    ██╔════╝██╔═══██╗██║     ██║     ██╔════╝██╔════╝╚══██╔══╝██╔═══██╗██╔══██╗██╔════╝
       ██║   ███████║█████╗      ██║     ██║   ██║██║     ██║     █████╗  ██║        ██║   ██║   ██║██████╔╝███████╗
       ██║   ██╔══██║██╔══╝      ██║     ██║   ██║██║     ██║     ██╔══╝  ██║        ██║   ██║   ██║██╔══██╗╚════██║
       ██║   ██║  ██║███████╗    ╚██████╗╚██████╔╝███████╗███████╗███████╗╚██████╗   ██║   ╚██████╔╝██║  ██║███████║
       ╚═╝   ╚═╝  ╚═╝╚══════╝     ╚═════╝ ╚═════╝ ╚══════╝╚══════╝╚══════╝ ╚═════╝   ╚═╝    ╚═════╝ ╚═╝  ╚═╝╚══════╝

    ███╗   ██╗███████╗████████╗    ██╗   ██╗ █████╗ ██╗   ██╗██╗  ████████╗    ███████╗███████╗ █████╗ ██████╗  ██████╗ ██████╗ ████████╗
    ████╗  ██║██╔════╝╚══██╔══╝    ██║   ██║██╔══██╗██║   ██║██║  ╚══██╔══╝    ██╔════╝██╔════╝██╔══██╗██╔══██╗██╔═══██╗██╔══██╗╚══██╔══╝
    ██╔██╗ ██║█████╗     ██║       ██║   ██║███████║██║   ██║██║     ██║       ███████╗█████╗  ███████║██████╔╝██║   ██║██████╔╝   ██║
    ██║╚██╗██║██╔══╝     ██║       ╚██╗ ██╔╝██╔══██║██║   ██║██║     ██║       ╚════██║██╔══╝  ██╔══██║██╔═══╝ ██║   ██║██╔══██╗   ██║
    ██║ ╚████║██║        ██║        ╚████╔╝ ██║  ██║╚██████╔╝███████╗██║       ███████║███████╗██║  ██║██║     ╚██████╔╝██║  ██║   ██║
    ╚═╝  ╚═══╝╚═╝        ╚═╝         ╚═══╝  ╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚═╝       ╚══════╝╚══════╝╚═╝  ╚═╝╚═╝      ╚═════╝ ╚═╝  ╚═╝   ╚═╝

     █████╗  ██████╗ ██████╗███████╗██████╗ ████████╗██╗███╗   ██╗ ██████╗      ██████╗ ███████╗███████╗███████╗██████╗ ███████╗
    ██╔══██╗██╔════╝██╔════╝██╔════╝██╔══██╗╚══██╔══╝██║████╗  ██║██╔════╝     ██╔═══██╗██╔════╝██╔════╝██╔════╝██╔══██╗██╔════╝
    ███████║██║     ██║     █████╗  ██████╔╝   ██║   ██║██╔██╗ ██║██║  ███╗    ██║   ██║█████╗  █████╗  █████╗  ██████╔╝███████╗
    ██╔══██║██║     ██║     ██╔══╝  ██╔═══╝    ██║   ██║██║╚██╗██║██║   ██║    ██║   ██║██╔══╝  ██╔══╝  ██╔══╝  ██╔══██╗╚════██║
    ██║  ██║╚██████╗╚██████╗███████╗██║        ██║   ██║██║ ╚████║╚██████╔╝    ╚██████╔╝██║     ██║     ███████╗██║  ██║███████║
    ╚═╝  ╚═╝ ╚═════╝ ╚═════╝╚══════╝╚═╝        ╚═╝   ╚═╝╚═╝  ╚═══╝ ╚═════╝      ╚═════╝ ╚═╝     ╚═╝     ╚══════╝╚═╝  ╚═╝╚══════╝

    ███████╗ █████╗  ██████╗███████╗████████╗
    ██╔════╝██╔══██╗██╔════╝██╔════╝╚══██╔══╝
    █████╗  ███████║██║     █████╗     ██║
    ██╔══╝  ██╔══██║██║     ██╔══╝     ██║
    ██║     ██║  ██║╚██████╗███████╗   ██║
    ╚═╝     ╚═╝  ╚═╝ ╚═════╝╚══════╝   ╚═╝
    @dev
    The facet that handling all opensea Seaport protocol accepting offers logic
    and can be called only by @TheCollectorsNFTVaultDiamond
    This contract is part of a diamond / facets implementation as described
    in EIP 2535 (https://eips.ethereum.org/EIPS/eip-2535)
*/
contract TheCollectorsNFTVaultSeaportAcceptingOffersFacet is TheCollectorsNFTVaultBaseFacet {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // ==================== Upgrade ====================

    /*
        @dev
        Upgrade to version 1.1
        - Added accepting offers
        - Added lowering price
        - Reorganized code
    */
    function upgradeVaultsAssetsHoldersAndProperties(uint256 numOfVaults, address nftVaultAssetHolderImpl) external {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        // New implementation
        _as.nftVaultAssetHolderImpl = nftVaultAssetHolderImpl;
        for (uint64 vaultId; vaultId < numOfVaults;) {
            LibDiamond.Vault storage vault = _as.vaults[vaultId];
            if (vault.collection == address (0)) {
                return;
            }
            vault.isListedNFT = vault.votingFor == LibDiamond.VoteFor.CancellingSellOrder;
            vault.isPurchasedNFT = vault.votingFor == LibDiamond.VoteFor.CancellingSellOrder || vault.votingFor == LibDiamond.VoteFor.Selling;
            vault.votingFor = LibDiamond.VoteFor.Nothing;

            address assetsHolder = _as.assetsHolders[vaultId];

            address payable newAssetsHolder = payable(
                new TheCollectorsNFTVaultSeaportAssetsHolderProxy(_as.nftVaultAssetHolderImpl, vaultId)
            );

            if (vault.isPurchasedNFT) {

                bool isVaultSoldToken;
                if (_as.vaultsExtensions[vaultId].isERC1155) {
                    isVaultSoldToken = IERC1155(_as.vaults[vaultId].collection).balanceOf(assetsHolder, _as.vaults[vaultId].tokenId) == 0;
                } else {
                    isVaultSoldToken = IERC721(_as.vaults[vaultId].collection).ownerOf(_as.vaults[vaultId].tokenId) != assetsHolder;
                }

                if (isVaultSoldToken) {
                    IAssetsHolderImpl(assetsHolder).sendValue(
                        newAssetsHolder, assetsHolder.balance
                    );
                } else {
                    IAssetsHolderImpl(assetsHolder).transferToken(
                        _as.vaultsExtensions[vaultId].isERC1155, newAssetsHolder, vault.collection, vault.tokenId
                    );
                }
            }

            // Replacing assets holders that can accept offers
            _as.assetsHolders[vaultId] = newAssetsHolder;
            unchecked {
                vaultId++;
            }
        }
    }

    // ==================== Logic ====================

    /*
        @dev
        Setting an accept offer of price for the underlying NFT.
        Later, participants can vote for or against accepting an offer at this price.
        Participants can call this method again in order to change the price of the offer to accept.
    */
    function setAcceptingOfferPrice(uint64 vaultId, uint128 acceptOfferOf) external {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        LibDiamond.Vault storage vault = _as.vaults[vaultId];
        require(vault.isPurchasedNFT, "E1");
        vault.acceptOfferOf = acceptOfferOf;
        bool isParticipant;
        uint24 numberOfParticipants = _as.vaultsExtensions[vaultId].numberOfParticipants;
        for (uint256 i; i < numberOfParticipants;) {
            LibDiamond.Participant storage participant = _as.vaultParticipants[vaultId][i];
            if (participant.participant == msg.sender) {
                // Only participants who has ownership can be part of the decision making
                // Can check ownership > 0 and not call @_getPercentage because this method can be
                // called only after purchasing
                // Using ownership > 0 will save gas
                require(participant.ownership > 0, "E2");
                isParticipant = true;
                _resetVotesAndGracePeriod(vaultId, true);
                vault.votingFor = LibDiamond.VoteFor.AcceptingOffer;
                emit AcceptingOfferOfPriceWasSet(vault.id, vault.collection, vault.tokenId, acceptOfferOf);
                _vote(vaultId, participant, true);
                break;
            }
            unchecked {
                i++;
            }
        }
        require(isParticipant, "E3");
    }

    // ==================== Seaport ====================

    /*
        @dev
        Accepting an offer that was specifically created for the underlying NFT
    */
    function acceptNFTOfferOnSeaport(uint64 vaultId, BasicOrderParameters calldata parameters) external nonReentrant {

        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        LibDiamond.Vault storage vault = _as.vaults[vaultId];

        uint256 offerPrice = parameters.offerAmount;
        uint256 fees;
        for (uint256 i; i < parameters.additionalRecipients.length;) {
            fees += parameters.additionalRecipients[i].amount;
            unchecked {
                ++i;
            }
        }

        uint256 royaltiesOnChain;
        try LibDiamond.MANIFOLD_ROYALTY_REGISTRY.getRoyaltyView(vault.collection, vault.tokenId, offerPrice)
        returns (address payable[] memory, uint256[] memory amounts) {
            for (uint256 i; i < amounts.length;) {
                royaltiesOnChain += amounts[i];
                unchecked {
                    ++i;
                }
            }
        } catch {}

        require(vault.votingFor == LibDiamond.VoteFor.AcceptingOffer, "E1");

        // Making sure that the offer is for the agreed upon price
        require(vault.acceptOfferOf > 0 && vault.acceptOfferOf <= offerPrice, "E2");

        // Accepting offers only when 100% of all participants agree to prevent an attack where
        // participant with majority ownership will accept an offer from himself for low amount
        require(_isVaultPassedSellOrCancelSellOrderConsensus(vaultId, 100 ether), "E3");
        // Not checking if the sender is a participant to save gas.

        uint256 netSalePrice = offerPrice - fees;
        uint256 royaltiesPercentage;
        if (royaltiesOnChain > 0) {
            royaltiesPercentage = royaltiesOnChain * LibDiamond.PERCENTAGE_DENOMINATOR / offerPrice;
        } else {
            // There isn't any royalties on chain info, using 10% as it is the maximum royalty on Opensea
            // offerAmount should be at least 87.5% of the listing price
            // This can open a weird attack where one of the vault participants will send their address as the royalties receiver
            // however, this will prevent Opensea from publish the order on the website. So this would be worth while only if
            // the "attacker" will buy the NFT directly from the vault but using Seaport contracts
            royaltiesPercentage = 1000;
        }

        require(netSalePrice >= offerPrice * (LibDiamond.PERCENTAGE_DENOMINATOR - 250 - royaltiesPercentage) / LibDiamond.PERCENTAGE_DENOMINATOR, "E5");

        require(
            vault.collection == parameters.considerationToken
            && vault.tokenId == parameters.considerationIdentifier
            && parameters.considerationAmount == 1, "CE");

        vault.netSalePrice = uint128(netSalePrice);

        (address conduitAddress,bool exists) = LibDiamond.OPENSEA_SEAPORT_CONDUIT_CONTROLLER.getConduit(parameters.offererConduitKey);
        require(exists, "Conduit does not exist");

        TheCollectorsNFTVaultSeaportAssetsHolderImpl(_as.assetsHolders[vaultId]).acceptNFTOfferOnSeaport(
            parameters, _as.seaportAddress, conduitAddress
        );

        emit VaultAcceptedOffer(vault.id, vault.collection, vault.tokenId, offerPrice);
    }

    /*
        @dev
        Accepting an offer that was created for the collection
    */
    function acceptAdvancedNFTOfferOnSeaport(
        uint64 vaultId,
        AdvancedOrder calldata advancedOrder,
        CriteriaResolver[] calldata criteriaResolvers,
        bytes32 fulfillerConduitKey
    ) external nonReentrant {

        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        LibDiamond.Vault storage vault = _as.vaults[vaultId];

        uint256 offerPrice = advancedOrder.parameters.offer[0].endAmount;
        address considerationToken;
        {
            uint256 fees;
            for (uint256 i; i < advancedOrder.parameters.consideration.length;) {
                if (advancedOrder.parameters.consideration[i].itemType == ItemType.ERC20 ||
                    advancedOrder.parameters.consideration[i].itemType == ItemType.NATIVE) {
                    fees += advancedOrder.parameters.consideration[i].endAmount;
                }
                unchecked {
                    ++i;
                }
            }

            uint256 royaltiesOnChain;
            try LibDiamond.MANIFOLD_ROYALTY_REGISTRY.getRoyaltyView(vault.collection, vault.tokenId, offerPrice)
            returns (address payable[] memory, uint256[] memory amounts) {
                for (uint256 i; i < amounts.length;) {
                    royaltiesOnChain += amounts[i];
                    unchecked {
                        ++i;
                    }
                }
            } catch {}

            require(vault.votingFor == LibDiamond.VoteFor.AcceptingOffer, "E1");

            // Making sure that the offer is for the agreed upon price
            require(vault.acceptOfferOf > 0 && vault.acceptOfferOf <= offerPrice, "E2");

            // Accepting offers only when 100% of all participants agree to prevent an attack where
            // participant with majority ownership will accept an offer from himself for low amount
            require(_isVaultPassedSellOrCancelSellOrderConsensus(vaultId, 100 ether), "E3");
            // Not checking if the sender is a participant to save gas.

            uint256 netSalePrice = offerPrice - fees;
            uint256 royaltiesPercentage;
            if (royaltiesOnChain > 0) {
                royaltiesPercentage = royaltiesOnChain * LibDiamond.PERCENTAGE_DENOMINATOR / offerPrice;
            } else {
                // There isn't any royalties on chain info, using 10% as it is the maximum royalty on Opensea
                // offerAmount should be at least 87.5% of the listing price
                // This can open a weird attack where one of the vault participants will send their address as the royalties receiver
                // however, this will prevent Opensea from publish the order on the website. So this would be worth while only if
                // the "attacker" will buy the NFT directly from the vault but using Seaport contracts
                royaltiesPercentage = 1000;
            }

            require(netSalePrice >= offerPrice * (LibDiamond.PERCENTAGE_DENOMINATOR - 250 - royaltiesPercentage) / LibDiamond.PERCENTAGE_DENOMINATOR, "E5");

            for (uint256 i; i < advancedOrder.parameters.consideration.length;) {
                if (advancedOrder.parameters.consideration[i].itemType != ItemType.ERC20 &&
                    advancedOrder.parameters.consideration[i].itemType != ItemType.NATIVE) {

                    require(
                        vault.collection == advancedOrder.parameters.consideration[i].token
                        // Can't check identifierOrCriteria since it is a collection offer
                        && advancedOrder.parameters.consideration[i].endAmount == 1, "CE");

                    considerationToken = advancedOrder.parameters.consideration[i].token;
                    break;
                }
                unchecked {
                    ++i;
                }
            }

            vault.netSalePrice = uint128(netSalePrice);
        }

        (address conduitAddress,bool exists) = LibDiamond.OPENSEA_SEAPORT_CONDUIT_CONTROLLER.getConduit(advancedOrder.parameters.conduitKey);
        require(exists, "Conduit does not exist");

        TheCollectorsNFTVaultSeaportAssetsHolderImpl(_as.assetsHolders[vaultId]).acceptAdvancedNFTOfferOnSeaport(
            advancedOrder, criteriaResolvers, fulfillerConduitKey, _as.seaportAddress, conduitAddress, considerationToken
        );

        emit VaultAcceptedOffer(vault.id, vault.collection, vault.tokenId, offerPrice);
    }

    // ==================== Internals ====================

    /*
        @dev
        Internal vote method to update participant vote
    */
    function _vote(uint64 vaultId, LibDiamond.Participant storage participant, bool yes) internal {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        LibDiamond.Vault storage vault = _as.vaults[vaultId];
        participant.vote = yes;
        participant.voteDate = uint48(block.timestamp);
        emit VotedForAcceptOffer(vaultId, participant.participant, yes, vault.collection, vault.tokenId, vault.acceptOfferOf);
    }

}