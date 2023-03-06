// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;


struct MakerOrder {
    bool side; // true --> ask / false --> bid
    address signer; // signer of the maker order
    address policy; // policy for trade execution (e.g., DutchAuction, StandardSaleForFixedPrice)
    address payment; // payment currency (e.g., WETH)
    uint256 nonce; // order nonce (must be unique unless new maker order is meant to override existing one e.g., lower ask price)
    uint256 startTime; // startTime in timestamp
    uint256 endTime; // endTime in timestamp
    bytes params; // additional parameters
    uint8 v; // v: parameter (27 or 28)
    bytes32 r; // r: parameter
    bytes32 s; // s: parameter
}

struct TakerOrder {
    bool side;                      // true --> ask / false --> bid
    address taker;                  // msg.sender
    Fulfillment[] offerComponents;  // offer items
}

struct Fulfillment {
    uint256 orderIndex;
    uint256 itemIndex;
    uint256 amount;
}

struct Properties {
    ItemType itemType;  // item type
    address collection; // collection address
    uint256 royaltyFee;
    address royaltyFeeRecipient;
    uint256 protocolFee;
    uint256 price;
    uint256 tokenId;
    uint256 amount;
}

struct AdvanceOrder {
    address policy;
    address payment;
    address signer;
    uint256 nonce;
    Properties[] items;        // order items
    bytes32 orderHash;
}

enum ItemType {
    NATIVE,  // 0: ETH on mainnet, MATIC on polygon, etc.

    ERC20,   // 1: ERC20 items (ERC777 and ERC20 analogues could also technically work)

    ERC721,  // 2: ERC721 items

    ERC1155, // 3: ERC1155 items

    ERC721_WITH_CRITERIA, // 4: ERC721 items where a number of tokenIds are supported

    ERC1155_WITH_CRITERIA // 5: ERC1155 items where a number of ids are supported
}

struct ERC721NFT {
    address collection;
    uint256[] tokenIds;
}

struct ERC1155NFT {
    address collection;
    uint256[] tokenIds;
    uint256[] amounts;
}