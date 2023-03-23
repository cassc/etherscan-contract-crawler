// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

enum OrderType {
    ETH_TO_ERC721,
    ETH_TO_ERC1155,

    ERC20_TO_ERC721,
    ERC20_TO_ERC1155,

    ERC721_TO_ERC20,
    ERC1155_TO_ERC20
}

/**
 * @title OrderTypes
 * @notice This library contains order types for Dyve
 */
library OrderTypes {
    // keccak256("Order(uint256 orderType,address signer,address collection,uint256 tokenId,uint256 amount,uint256 duration,uint256 collateral,uint256 fee,address currency,uint256 nonce,uint256 endTime)")
    bytes32 internal constant ORDER_HASH = 0xaad599fc66ff6b968ccb16010214cc3102e0a7e009000f61cab3f208682c3088;

    struct Order {
        OrderType orderType; // the type of order
        address signer; // signer of the maker order
        address collection; // collection address
        uint256 tokenId; // id of the token
        uint256 amount; // amount of the token (only applicable for ERC1155, always set to 1 for ERC721)
        uint256 duration; // duration of the borrow
        uint256 collateral; // collateral amount
        uint256 fee; // fee for the lender
        address currency; // currency (e.g., WETH)
        address premiumCollection; // premium collection address
        uint256 premiumTokenId; // premium token id
        uint256 nonce; // order nonce (must be unique unless new maker order is meant to override existing one e.g., lower ask price)
        uint256 endTime; // time when the order expires in epoch seconds
        bytes signature; // signature of the maker order
    }

    function hash(Order memory order) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    ORDER_HASH,
                    order.orderType,
                    order.signer,
                    order.collection,
                    order.tokenId,
                    order.amount,
                    order.duration,
                    order.collateral,
                    order.fee,
                    order.currency,
                    order.nonce,
                    order.endTime
                )
            );
    }
}