// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library Orders {
    bytes32 internal constant ORDER_TYPEHASH = 0x769fab4c8e7775520a45b1ec3ead4f5c0187be9971238d0ff4f7a4ff1f1d6e31;
    // ORDER_TYPEHASH = keccak256(
    //     "Order(bool isAsk,address signer,uint256 nonce,uint256 startTime,uint256 endTime,address collection,uint256 tokenId,uint256 amount,uint256 price,address currency)"
    // );

    struct Order {
        bool isAsk; // false if bid
        address signer; // the signer address
        uint256 nonce; // used for cancelling orders, should be unique
        uint256 startTime; // timestamp after which order is active
        uint256 endTime; // timestamp after which order is no longer active
        address collection; // asset collection contract address
        uint256 tokenId; // asset token id
        uint256 amount; // amount of assets
        uint256 price; // the ask/bid price
        address currency; // ERC20 token contract address
        uint8 v; // v: parameter (27 or 28)
        bytes32 r; // r: parameter
        bytes32 s; // s: parameter
    }

    function hash(Orders.Order memory order) internal pure returns (bytes32) {
        return keccak256(
            abi.encode(
                ORDER_TYPEHASH,
                order.isAsk,
                order.signer,
                order.nonce,
                order.startTime,
                order.endTime,
                order.collection,
                order.tokenId,
                order.amount,
                order.price,
                order.currency
            )
        );
    }
}