// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library OrderTypes {
    struct OrderItem {
        address collection;
        uint256 tokenId;
        uint256 amount;
        uint256 price;
    }

    struct MakerOrder {
        bool isAsk;
        address signer;
        OrderItem[] items;
        address strategy;
        address currency;
        uint256 nonce;
        uint256 startTime;
        uint256 endTime;
        uint256 minPercentageToAsk;
        bytes32 marketplace;
        bytes params;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    struct TakerOrder {
        bool isAsk;
        address taker;
        uint256 itemIdx;
        OrderItem item;
        uint256 minPercentageToAsk;
        bytes32 marketplace;
        bytes params;
    }

    struct Fulfillment {
        address collection;
        uint256 tokenId;
        uint256 amount;
        address currency;
        uint256 price;
    }

    function hash(OrderItem memory orderItem) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256(
                        "OrderItem(address collection,uint256 tokenId,uint256 amount,uint256 price)"
                    ),
                    orderItem.collection,
                    orderItem.tokenId,
                    orderItem.amount,
                    orderItem.price
                )
            );
    }

    function hash(MakerOrder memory makerOrder)
        internal
        pure
        returns (bytes32)
    {
        bytes32[] memory itemsHash = new bytes32[](makerOrder.items.length);
        for (uint256 i = 0; i < makerOrder.items.length; i++) {
            itemsHash[i] = hash(makerOrder.items[i]);
        }
        return
            keccak256(
                abi.encode(
                    keccak256(
                        "MakerOrder(bool isAsk,address signer,OrderItem[] items,address strategy,address currency,uint256 nonce,uint256 startTime,uint256 endTime,uint256 minPercentageToAsk,bytes32 marketplace,bytes params)OrderItem(address collection,uint256 tokenId,uint256 amount,uint256 price)"
                    ),
                    makerOrder.isAsk,
                    makerOrder.signer,
                    keccak256(abi.encodePacked(itemsHash)),
                    makerOrder.strategy,
                    makerOrder.currency,
                    makerOrder.nonce,
                    makerOrder.startTime,
                    makerOrder.endTime,
                    makerOrder.minPercentageToAsk,
                    makerOrder.marketplace,
                    keccak256(makerOrder.params)
                )
            );
    }

    function hashOrderItem(MakerOrder memory makerOrder, uint256 idx)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    makerOrder.isAsk,
                    makerOrder.signer,
                    idx,
                    makerOrder.items[idx],
                    makerOrder.strategy,
                    makerOrder.currency,
                    makerOrder.nonce,
                    makerOrder.startTime,
                    makerOrder.endTime,
                    makerOrder.minPercentageToAsk,
                    makerOrder.params
                )
            );
    }
}