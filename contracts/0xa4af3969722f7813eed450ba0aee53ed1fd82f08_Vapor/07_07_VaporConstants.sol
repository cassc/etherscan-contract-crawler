// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

bytes32 constant ITEM_TYPEHASH = keccak256(
    "Item(address token,uint8 itemType,uint256 value)"
);

bytes32 constant OFFER_TYPEHASH = keccak256(
    "Offer(Item[] toSend,Item[] toReceive,address from,address to,uint256 deadline)Item(address token,uint8 itemType,uint256 value)"
);

bytes32 constant DOMAIN_TYPEHASH = keccak256(
    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
);