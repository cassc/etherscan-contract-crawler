// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import {RouterImmutables} from "../base/RouterImmutables.sol";
import {ERC721} from "solmate/src/tokens/ERC721.sol";
import {ERC1155} from "solmate/src/tokens/ERC1155.sol";

abstract contract HandleReservoir is RouterImmutables {
    enum ReservoirOfferMarket {
        OPENSEA,
        LOOKSRARE,
        X2Y2
    }

    struct ReservoirOfferStruct {
        ReservoirOfferMarket offerMarket;
        uint256 tokenStandard;
        address collection;
        uint256 tokenId;
        uint256 tokenAmount; 
        bytes inputDate;
        uint offerAmount;
    }

    /// @notice look for the market
    /// @param offerMarket enum for market
    /// @return address of market
    function getOfferMarketAddress(
        ReservoirOfferMarket offerMarket
    ) internal view returns (address) {
        if (offerMarket == ReservoirOfferMarket.OPENSEA) {
            return SEAPORTMODULE; // SeaportModule
        } else if (offerMarket == ReservoirOfferMarket.LOOKSRARE) {
            return LOOKSRAREMODULE; // LooksRareModule
        } else if (offerMarket == ReservoirOfferMarket.X2Y2) {
            return X2Y2MODULE; // X2Y2Module
        } else {
            revert("HandleReservoir:OfferMarket Error");
        }
    }

    /// @notice sell NFT
    /// @param reservoirOffers data about offer
    function handleReservoirSell(
        ReservoirOfferStruct[] memory reservoirOffers
    ) internal {
        for (uint256 i; i < reservoirOffers.length; ) {
            ReservoirOfferStruct memory reservoirOffer = reservoirOffers[i];

            if (reservoirOffer.tokenStandard == 721) {
                uint256 beforeTransferBalance = WETH9.balanceOf(address(this));
                ERC721(reservoirOffer.collection).safeTransferFrom(
                    msg.sender,
                    getOfferMarketAddress(reservoirOffer.offerMarket),
                    reservoirOffer.tokenId,
                    reservoirOffer.inputDate
                );
                uint256 afterTransferBalance = WETH9.balanceOf(address(this));
                require(
                    afterTransferBalance - beforeTransferBalance >=
                        reservoirOffer.offerAmount,
                    "HandleReservoir:OfferAmount Error"
                );
            } else if (reservoirOffer.tokenStandard == 1155) {
                uint256 beforeTransferBalance = WETH9.balanceOf(address(this));
                ERC1155(reservoirOffer.collection).safeTransferFrom(
                    msg.sender,
                    getOfferMarketAddress(reservoirOffer.offerMarket),
                    reservoirOffer.tokenId,
                    reservoirOffer.tokenAmount,
                    reservoirOffer.inputDate
                );
                uint256 afterTransferBalance = WETH9.balanceOf(address(this));
                require(
                    afterTransferBalance - beforeTransferBalance >=
                        reservoirOffer.offerAmount,
                    "HandleReservoir:OfferAmount Error"
                );
            } else {
                revert("HandleReservoir:TokenStandard Error");
            }

            unchecked {
                ++i;
            }
        }
    }
}