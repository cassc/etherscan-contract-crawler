// SPDX-License-Identifier: UNLICENSED
// © 2022 The Collectors. All rights reserved.
pragma solidity ^0.8.13;

import "./TheCollectorsNFTVaultBaseFacet.sol";
import "../TheCollectorsNFTVaultSeaportAssetsHolderImpl.sol";
import {BasicOrderParameters, OrderComponents, Order, Fulfillment} from "../SeaportStructs.sol";
import {ItemType} from "../SeaportEnums.sol";

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
    ███████╗███████╗ █████╗ ██████╗  ██████╗ ██████╗ ████████╗
    ██╔════╝██╔════╝██╔══██╗██╔══██╗██╔═══██╗██╔══██╗╚══██╔══╝
    ███████╗█████╗  ███████║██████╔╝██║   ██║██████╔╝   ██║
    ╚════██║██╔══╝  ██╔══██║██╔═══╝ ██║   ██║██╔══██╗   ██║
    ███████║███████╗██║  ██║██║     ╚██████╔╝██║  ██║   ██║
    ╚══════╝╚══════╝╚═╝  ╚═╝╚═╝      ╚═════╝ ╚═╝  ╚═╝   ╚═╝
    ███╗   ███╗ █████╗ ███╗   ██╗ █████╗  ██████╗ ███████╗██████╗     ███████╗ █████╗  ██████╗███████╗████████╗
    ████╗ ████║██╔══██╗████╗  ██║██╔══██╗██╔════╝ ██╔════╝██╔══██╗    ██╔════╝██╔══██╗██╔════╝██╔════╝╚══██╔══╝
    ██╔████╔██║███████║██╔██╗ ██║███████║██║  ███╗█████╗  ██████╔╝    █████╗  ███████║██║     █████╗     ██║
    ██║╚██╔╝██║██╔══██║██║╚██╗██║██╔══██║██║   ██║██╔══╝  ██╔══██╗    ██╔══╝  ██╔══██║██║     ██╔══╝     ██║
    ██║ ╚═╝ ██║██║  ██║██║ ╚████║██║  ██║╚██████╔╝███████╗██║  ██║    ██║     ██║  ██║╚██████╗███████╗   ██║
    ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚═╝  ╚═╝    ╚═╝     ╚═╝  ╚═╝ ╚═════╝╚══════╝   ╚═╝
    @dev
    The facet that handling all opensea Seaport protocol logic and can be called only by @TheCollectorsNFTVaultDiamond
    This contract is part of a diamond / facets implementation as described
    in EIP 2535 (https://eips.ethereum.org/EIPS/eip-2535)
*/
contract TheCollectorsNFTVaultSeaportManagerFacet is TheCollectorsNFTVaultBaseFacet {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // ==================== Seaport ====================

    /*
        @dev
        Buying the agreed upon token from Seaport using advanced order
        Not checking if msg.sender is a participant since a buy consensus must be met
    */
    function buyAdvancedNFTOnSeaport(
        uint64 vaultId,
        AdvancedOrder calldata advancedOrder,
        CriteriaResolver[] calldata criteriaResolvers,
        bytes32 fulfillerConduitKey
    ) external nonReentrant {

        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();

        uint256 prevERC1155Amount;

        if (_as.vaultsExtensions[vaultId].isERC1155) {
            prevERC1155Amount = IERC1155(_as.vaults[vaultId].collection).balanceOf(_as.assetsHolders[vaultId], _as.vaults[vaultId].tokenId);
        }

        uint256 purchasePrice;
        for (uint256 i; i < advancedOrder.parameters.consideration.length;) {
            if (advancedOrder.parameters.consideration[i].itemType == ItemType.NATIVE) {
                purchasePrice += advancedOrder.parameters.consideration[i].endAmount;
            }
            unchecked {
                ++i;
            }
        }

        uint256 totalPaid = _requireBuyConsensusAndValidatePurchasePrice(vaultId, purchasePrice);

        require(
            _as.vaults[vaultId].collection == advancedOrder.parameters.offer[0].token
            && _as.vaults[vaultId].tokenId == advancedOrder.parameters.offer[0].identifierOrCriteria
            && advancedOrder.parameters.offer[0].endAmount == 1, "CE");

        purchasePrice = TheCollectorsNFTVaultSeaportAssetsHolderImpl(_as.assetsHolders[vaultId]).buyAdvancedNFTOnSeaport(
            advancedOrder, criteriaResolvers, fulfillerConduitKey, purchasePrice, _as.seaportAddress
        );

        _afterPurchaseNFT(vaultId, purchasePrice, true, prevERC1155Amount, totalPaid);
    }

    /*
        @dev
        Buying the agreed upon token from Seaport using matched order
        Not checking if msg.sender is a participant since a buy consensus must be met
    */
    function buyMatchedNFTOnSeaport(
        uint64 vaultId,
        Order[] calldata orders,
        Fulfillment[] calldata fulfillments
    ) external nonReentrant {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();

        uint256 prevERC1155Amount;

        if (_as.vaultsExtensions[vaultId].isERC1155) {
            prevERC1155Amount = IERC1155(_as.vaults[vaultId].collection).balanceOf(_as.assetsHolders[vaultId], _as.vaults[vaultId].tokenId);
        }

        uint256 purchasePrice;
        for (uint256 i; i < orders[0].parameters.consideration.length;) {
            if (orders[0].parameters.consideration[i].itemType == ItemType.NATIVE) {
                purchasePrice += orders[0].parameters.consideration[i].endAmount;
            }
            unchecked {
                ++i;
            }
        }

        uint256 totalPaid = _requireBuyConsensusAndValidatePurchasePrice(vaultId, purchasePrice);

        for (uint256 i; i < orders.length;) {
            if (orders[i].parameters.offer[0].itemType != ItemType.NATIVE) {
                require(
                    _as.vaults[vaultId].collection == orders[i].parameters.offer[0].token
                    && _as.vaults[vaultId].tokenId == orders[i].parameters.offer[0].identifierOrCriteria
                    && orders[i].parameters.offer[0].endAmount == 1, "CE");
            }
            unchecked {
                ++i;
            }
        }

        purchasePrice = TheCollectorsNFTVaultSeaportAssetsHolderImpl(_as.assetsHolders[vaultId]).buyMatchedNFTOnSeaport(
            orders, fulfillments, purchasePrice, _as.seaportAddress
        );

        _afterPurchaseNFT(vaultId, purchasePrice, true, prevERC1155Amount, totalPaid);
    }

    /*
        @dev
        Buying the agreed upon token from Seaport using basic order
        Not checking if msg.sender is a participant since a buy consensus must be met
    */
    function buyNFTOnSeaport(uint64 vaultId, BasicOrderParameters calldata parameters) external nonReentrant {

        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        LibDiamond.Vault storage vault = _as.vaults[vaultId];

        uint256 prevERC1155Amount;

        if (_as.vaultsExtensions[vaultId].isERC1155) {
            prevERC1155Amount = IERC1155(vault.collection).balanceOf(_as.assetsHolders[vaultId], vault.tokenId);
        }

        uint256 purchasePrice = parameters.considerationAmount;
        for (uint256 i; i < parameters.additionalRecipients.length;) {
            purchasePrice += parameters.additionalRecipients[i].amount;
            unchecked {
                ++i;
            }
        }

        uint256 totalPaid = _requireBuyConsensusAndValidatePurchasePrice(vaultId, purchasePrice);

        require(
            vault.collection == parameters.offerToken && vault.tokenId == parameters.offerIdentifier
            && parameters.offerAmount == 1, "CE");

        purchasePrice = TheCollectorsNFTVaultSeaportAssetsHolderImpl(_as.assetsHolders[vaultId]).buyNFTOnSeaport(
            parameters, purchasePrice, _as.seaportAddress
        );

        _afterPurchaseNFT(vaultId, purchasePrice, true, prevERC1155Amount, totalPaid);
    }

    /*
        @dev
        Approving the sale order in Seaport protocol.
        Please be aware that a client will still need to call opensea API to show the listing on opensea website.
        Need to check if msg.sender is a participant since after grace period is over, all undecided votes
        are considered as yes which might make the sell consensus pass
        This method verifies that this order that was sent will pass the verification done by Opensea API and it will
        be published on Opensea website
    */
    function listNFTOnSeaport(uint64 vaultId, Order memory order) external {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        LibDiamond.Vault storage vault = _as.vaults[vaultId];
        LibDiamond.VaultExtension storage vaultExtension = _as.vaultsExtensions[vaultId];
        address payable assetsHolder = _as.assetsHolders[vaultId];

        uint256 royaltiesOnChain;
        try LibDiamond.MANIFOLD_ROYALTY_REGISTRY.getRoyaltyView(vault.collection, vault.tokenId, vault.listFor)
        returns (address payable[] memory, uint256[] memory amounts) {
            for (uint256 i; i < amounts.length;) {
                royaltiesOnChain += amounts[i];
                unchecked {
                    ++i;
                }
            }
        } catch {}

        uint256 netSalePrice;
        {
            uint256 listPrice;
            uint256 openseaFees;
            uint256 creatorRoyalties;
            for (uint256 i; i < order.parameters.consideration.length;) {
                listPrice += order.parameters.consideration[i].endAmount;
                if (order.parameters.consideration[i].recipient == assetsHolder) {
                    netSalePrice = order.parameters.consideration[i].endAmount;
                } else if (_isOpenseaRecipient(order.parameters.consideration[i].recipient)) {
                    openseaFees = order.parameters.consideration[i].endAmount;
                } else {
                    creatorRoyalties = order.parameters.consideration[i].endAmount;
                }
                // No private sales
                require(order.parameters.consideration[i].itemType == ItemType.NATIVE, "E0");
                unchecked {
                    ++i;
                }
            }
            require(vault.votingFor == LibDiamond.VoteFor.Selling, "E1");

            // Making sure that list for was set and the sell price is the agreed upon price
            require(vault.listFor > 0 && vault.listFor == listPrice, "E2");

            require(isVaultPassedSellOrCancelSellOrderConsensus(vaultId), "E3");
            // Not checking if the sender is a participant to save gas.

            require(openseaFees == listPrice * 250 / LibDiamond.PERCENTAGE_DENOMINATOR, "E5");
            if (royaltiesOnChain > 0) {
                require(creatorRoyalties == royaltiesOnChain, "E5");
                uint256 royaltiesPercentage = royaltiesOnChain * LibDiamond.PERCENTAGE_DENOMINATOR / listPrice;
                require(netSalePrice == listPrice * (LibDiamond.PERCENTAGE_DENOMINATOR - 250 - royaltiesPercentage) / LibDiamond.PERCENTAGE_DENOMINATOR, "E5");
            } else {
                // There isn't any royalties on chain info, using 10% as it is the maximum royalty on Opensea
                // netSalePrice should be at least 87.5% of the listing price
                // This can open a weird attack where one of the vault participants will send their address as the royalties receiver
                // however, this will prevent Opensea from publish the order on the website. So this would be worth while only if
                // the "attacker" will buy the NFT directly from the vault but using Seaport contracts
                require(netSalePrice >= listPrice * (LibDiamond.PERCENTAGE_DENOMINATOR - 250 - 1000) / LibDiamond.PERCENTAGE_DENOMINATOR, "E5");
            }

            // Not checking if the asset holder is actually holding the asset to save gas.

            require(
                vault.collection == order.parameters.offer[0].token
                && vault.tokenId == order.parameters.offer[0].identifierOrCriteria
                && order.parameters.offer[0].endAmount == 1, "CE");
        }

        vault.netSalePrice = uint128(netSalePrice);

        (address conduitAddress,bool exists) = LibDiamond.OPENSEA_SEAPORT_CONDUIT_CONTROLLER.getConduit(order.parameters.conduitKey);
        require(exists, "Conduit does not exist");

        TheCollectorsNFTVaultSeaportAssetsHolderImpl(assetsHolder).listNFTOnSeaport(
            order, _as.seaportAddress, conduitAddress
        );

        _resetVotesAndGracePeriod(vaultId);

        vault.votingFor = LibDiamond.VoteFor.CancellingSellOrder;
        vaultExtension.listingBlockNumber = uint64(block.number);

        emit NFTListedForSale(vault.id, vault.collection, vault.tokenId, vault.listFor, order);
    }

    /*
        @dev
        Canceling a previous sale order in Seaport protocol.
        This function must be called before re-listing with another price.
    */
    function cancelNFTListingOnSeaport(uint64 vaultId, OrderComponents[] memory order) external {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        LibDiamond.Vault storage vault = _as.vaults[vaultId];
        address payable assetsHolder = _as.assetsHolders[vaultId];

        require(vault.votingFor == LibDiamond.VoteFor.CancellingSellOrder, "E1");
        // Not checking if the sender is a participant to save gas.
        require(isVaultPassedSellOrCancelSellOrderConsensus(vaultId), "E3");
        // Not checking if the asset holder is actually holding the asset to save gas.

        require(
            vault.collection == order[0].offer[0].token
            && vault.tokenId == order[0].offer[0].identifierOrCriteria
            && order[0].offer[0].endAmount == 1, "CE");

        TheCollectorsNFTVaultSeaportAssetsHolderImpl(assetsHolder).cancelNFTListingOnSeaport(
            order, _as.seaportAddress
        );

        _resetVotesAndGracePeriod(vaultId);

        vault.votingFor = LibDiamond.VoteFor.Selling;

        emit NFTSellOrderCanceled(vaultId, vault.collection, vault.tokenId);
    }

    // ==================== Seaport Management ====================

    /*
        @dev
        Set seaport address as it can change from time to time
    */
    function setSeaportAddress(address _seaportAddress) external onlyOwner {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        _as.seaportAddress = _seaportAddress;
    }

    /*
        @dev
        Set opensea fee recipients to verify 2.5% fee
    */
    function setOpenseaFeeRecipients(address[] calldata _openseaFeeRecipients) external onlyOwner {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        _as.openseaFeeRecipients = _openseaFeeRecipients;
    }

    function _isOpenseaRecipient(address recipient) internal view returns (bool) {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        address[] memory openseaFeeRecipients = _as.openseaFeeRecipients;
        for (uint256 i; i < openseaFeeRecipients.length;) {
            if (recipient == openseaFeeRecipients[i]) {
                return true;
            }
            unchecked {
                ++i;
            }
        }
        return false;
    }
}