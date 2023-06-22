// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

library OrderLib {
    enum OrderType {
        SellerOrder,
        BuyerOrder
    }

    struct BuyOrder {
        uint8 commodityType;
        uint32 endDay;
        uint32 orderExpirationTimestamp;
        uint32 salt;
        uint256 resourceAmount;
        uint256 unitPrice;
        address signerAddress;
        address rewardToken;
        address paymentToken;
        address vaultAddress;
    }

    struct SellOrder {
        uint8 commodityType;
        uint32 endDay;
        uint32 orderExpirationTimestamp;
        uint32 salt;
        uint256 resourceAmount;
        uint256 unitPrice;
        address signerAddress;
        address rewardToken;
        address paymentToken;
        uint256 additionalCollateralPercent;
    }

    bytes32 public constant BUY_ORDER_TYPEHASH =
        keccak256(
            "BuyOrder(uint8 commodityType,uint32 endDay,uint32 orderExpirationTimestamp,uint32 salt,uint256 resourceAmount,uint256 unitPrice,address signerAddress,address rewardToken,address paymentToken,address vaultAddress)"
        );

    bytes32 public constant SELL_ORDER_TYPEHASH =
        keccak256(
            "SellOrder(uint8 commodityType,uint32 endDay,uint32 orderExpirationTimestamp,uint32 salt,uint256 resourceAmount,uint256 unitPrice,address signerAddress,address rewardToken,address paymentToken,uint256 additionalCollateralPercent)"
        );

    function getBuyOrderHash(OrderLib.BuyOrder memory order) internal pure returns (bytes32) {
        bytes32 structHash = keccak256(
            abi.encode(
                OrderLib.BUY_ORDER_TYPEHASH,
                order.commodityType,
                order.endDay,
                order.orderExpirationTimestamp,
                order.salt,
                order.resourceAmount,
                order.unitPrice,
                order.signerAddress,
                order.rewardToken,
                order.paymentToken,
                order.vaultAddress
            )
        );

        return structHash;
    }

    function getSellOrderHash(OrderLib.SellOrder memory order) internal pure returns (bytes32) {
        bytes32 structHash = keccak256(
            abi.encode(
                OrderLib.SELL_ORDER_TYPEHASH,
                order.commodityType,
                order.endDay,
                order.orderExpirationTimestamp,
                order.salt,
                order.resourceAmount,
                order.unitPrice,
                order.signerAddress,
                order.rewardToken,
                order.paymentToken,
                order.additionalCollateralPercent
            )
        );

        return structHash;
    }

    function getTypedDataHash(OrderLib.BuyOrder calldata _order, bytes32 DOMAIN_SEPARATOR) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, getBuyOrderHash(_order)));
    }

    function getTypedDataHash(OrderLib.SellOrder calldata _order, bytes32 DOMAIN_SEPARATOR) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, getSellOrderHash(_order)));
    }
}