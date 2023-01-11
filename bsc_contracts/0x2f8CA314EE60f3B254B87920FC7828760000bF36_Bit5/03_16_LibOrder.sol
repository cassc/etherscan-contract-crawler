// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

enum OrderStatus {
    NOT_PROCESSED,
    FILLED,
    CANCELED
}

enum OrderKind {
    BID,
    LIST
}

enum TokenKind {
    ERC721,
    ERC1155
}

struct Order {
    address issuer;
    address nftAddress;
    address paymentToken;
    uint256 price;
    uint256 tokenId;
    uint256 amount;
    uint256 end;
    OrderKind kind;
    TokenKind tokenKind;
    uint256 globalBidAmount;
    PrivilegedInformation privileges;
}

struct PrivilegedInformation {
    address privilegedCollection;
    uint256 privilegedTokenId;
}

library LibOrder {
    bytes32 public constant PrivilegedInformation_TYPEHASH =
        keccak256(
            "PrivilegedInformation(address privilegedCollection,uint256 privilegedTokenId)"
        );
    bytes32 constant ORDER_TYPEHASH =
        keccak256(
            "Order(address issuer,address nftAddress,address paymentToken,uint256 price,uint256 tokenId,uint256 amount,uint256 end,uint256 kind,uint256 tokenKind,uint256 globalBidAmount,PrivilegedInformation privileges)PrivilegedInformation(address privilegedCollection,uint256 privilegedTokenId)"
        );

    function hash(Order memory order) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    ORDER_TYPEHASH,
                    order.issuer,
                    order.nftAddress,
                    order.paymentToken,
                    order.price,
                    order.tokenId,
                    order.amount,
                    order.end,
                    order.kind,
                    order.tokenKind,
                    order.globalBidAmount,
                    keccak256(
                        abi.encode(
                            PrivilegedInformation_TYPEHASH,
                            order.privileges.privilegedCollection,
                            order.privileges.privilegedTokenId
                        )
                    )
                )
            );
    }
}