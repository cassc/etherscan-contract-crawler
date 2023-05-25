// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {ListingTypes} from "../libraries/ListingTypes.sol";
import {OfferTypes} from "../libraries/OfferTypes.sol";

interface IExecutionStrategy {
    function canBuy(ListingTypes.Listing calldata listing, ListingTypes.ItemBuyer calldata itemBuyer) external view returns (bool, uint256, uint256);

    function canSell(OfferTypes.Offer calldata offer, OfferTypes.ItemSeller calldata itemSeller) external view returns (bool, uint256, uint256);
}