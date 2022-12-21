// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

library OrderLib {
    // solhint-disable-next-line var-name-mixedcase
    bytes32 public constant ORDER_TYPEHASH =
        keccak256(
            "Order(uint8 orderType,uint8 silicaType,uint32 endDay,uint32 orderExpirationTimestamp,uint32 salt,address buyerAddress,address sellerAddress,address rewardToken,address paymentToken,uint256 amount,uint256 feeAmount,uint256 unitPrice)"
        );

    enum OrderType {
        SellerOrder,
        BuyerOrder
    }

    struct Order {
        uint8 orderType;
        uint8 silicaType;
        uint32 endDay;
        uint32 orderExpirationTimestamp;
        uint32 salt;
        address buyerAddress;
        address sellerAddress;
        address rewardToken;
        address paymentToken;
        uint256 amount;
        uint256 feeAmount;
        uint256 unitPrice;
    }

    struct OrderFilledData {
        address silicaContract;
        bytes32 buyerOrderHash;
        bytes32 sellerOrderHash;
        address buyerAddress;
        address sellerAddress;
        uint256 unitPrice;
        uint256 endDay;
        uint256 totalPaymentAmount;
        uint256 reservedPrice;
    }

    function getOrderHash(OrderLib.Order calldata order) internal pure returns (bytes32) {
        bytes32 structHash = keccak256(
            abi.encode(
                OrderLib.ORDER_TYPEHASH,
                order.orderType,
                order.silicaType,
                order.endDay,
                order.orderExpirationTimestamp,
                order.salt,
                order.buyerAddress,
                order.sellerAddress,
                order.rewardToken,
                order.paymentToken,
                order.amount,
                order.feeAmount,
                order.unitPrice
            )
        );
        return structHash;
    }

    function getTypedDataHash(OrderLib.Order calldata _order, bytes32 DOMAIN_SEPARATOR) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, getOrderHash(_order)));
    }
}