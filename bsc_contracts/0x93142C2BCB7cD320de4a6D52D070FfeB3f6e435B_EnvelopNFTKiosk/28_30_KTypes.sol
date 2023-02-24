// SPDX-License-Identifier: MIT
// ENVELOP(NIFTSY) protocol V1 for NFT. 
import "LibEnvelopTypes.sol";

pragma solidity 0.8.16;
library KTypes {
	enum DiscountType {PROMO, REFERRAL, BATCH, TIME, WHITELIST, CUSTOM1, CUSTOM2, CUSTOM3}

    struct Price {
        address payWith;
        uint256 amount;
    }

    struct DenominatedPrice {
        address payWith;
        uint256 amount;
        uint256 denominator;
    }

    struct Discount {
        DiscountType dsctType;
        uint16 dsctPercent; // 100%-10000, 20%-2000, 3%-300
    }

    struct ItemForSale {
        address owner;
        ETypes.AssetItem nft;
        Price[] prices;
    }

    struct Display {
        address owner;
        address beneficiary; // who will receive assets from sale
        uint256 enableAfter;
        uint256 disableAfter;
        address priceModel;
        ItemForSale[] items;
    }

    struct Place {
        bytes32 display;
        uint256 index;
    }
}