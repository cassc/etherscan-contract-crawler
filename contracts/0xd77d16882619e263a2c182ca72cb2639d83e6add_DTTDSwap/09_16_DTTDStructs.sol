// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {
    OfferItemType
} from "./DTTDEnums.sol";

struct Swap {
    Offer[] offer;
    uint256 endTime;
    uint256 swapNonce;
}
// bytes32 constant SWAP_TYPEHASH = keccak256(
//     "Swap(Offer[] offer,uint256 endTime,uint256 swapNonce)"
//     "Offer(OfferItem[] offerItem,address from)"
//     "OfferItem(address to,uint8 offerItemType,address token,uint256 identifier,uint256 amount)"
// );
bytes32 constant SWAP_TYPEHASH = 0xe290609c8f553aa0c70e2b281e26afb435b47184686022e17fa2a505e19e51e2;


struct Offer {
    OfferItem[] offerItem;
    address from;
}
// bytes32 constant OFFER_TYPEHASH = keccak256(
//     "Offer(OfferItem[] offerItem,address from)"
//     "OfferItem(address to,uint8 offerItemType,address token,uint256 identifier,uint256 amount)"
// );
bytes32 constant OFFER_TYPEHASH = 0xf825b6e9e2bed18c730b3d709a3e36506e06d746be0813d0e476e624d41759a8;


struct OfferItem {
    address to;
    uint8 offerItemType; // we store as uint8 instead of enum to make it easier to support external signing
    address token;
    uint256 identifier;
    uint256 amount;
}
// bytes32 constant OFFERITEM_TYPEHASH = keccak256(
//     "OfferItem(address to,uint8 offerItemType,address token,uint256 identifier,uint256 amount)"
// );
bytes32 constant OFFERITEM_TYPEHASH = 0x8eca0abaaf13208f26a407164e441c3799b94efbfa2e91608e9c60aa9069302b;