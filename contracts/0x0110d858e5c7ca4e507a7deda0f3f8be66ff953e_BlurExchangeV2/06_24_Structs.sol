// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

struct TakeAsk {
    Order[] orders;
    Exchange[] exchanges;
    FeeRate takerFee;
    bytes signatures;
    address tokenRecipient;
}

struct TakeAskSingle {
    Order order;
    Exchange exchange;
    FeeRate takerFee;
    bytes signature;
    address tokenRecipient;
}

struct TakeBid {
    Order[] orders;
    Exchange[] exchanges;
    FeeRate takerFee;
    bytes signatures;
}

struct TakeBidSingle {
    Order order;
    Exchange exchange;
    FeeRate takerFee;
    bytes signature;
}

enum AssetType {
    ERC721,
    ERC1155
}

enum OrderType {
    ASK,
    BID
}

struct Exchange { // Size: 0x80
    uint256 index; // 0x00
    bytes32[] proof; // 0x20
    Listing listing; // 0x40
    Taker taker; // 0x60
}

struct Listing { // Size: 0x80
    uint256 index; // 0x00
    uint256 tokenId; // 0x20
    uint256 amount; // 0x40
    uint256 price; // 0x60
}

struct Taker { // Size: 0x40
    uint256 tokenId; // 0x00
    uint256 amount; // 0x20
}

struct Order { // Size: 0x100
    address trader; // 0x00
    address collection; // 0x20
    bytes32 listingsRoot; // 0x40
    uint256 numberOfListings; // 0x60
    uint256 expirationTime; // 0x80
    AssetType assetType; // 0xa0
    FeeRate makerFee; // 0xc0
    uint256 salt; // 0xe0
}

/*
Reference only; struct is composed manually using calldata formatting in execution
struct ExecutionBatch { // Size: 0x80
    address taker; // 0x00
    OrderType orderType; // 0x20
    Transfer[] transfers; // 0x40
    uint256 length; // 0x60
}
*/

struct Transfer { // Size: 0xa0
    address trader; // 0x00
    uint256 id; // 0x20
    uint256 amount; // 0x40
    address collection; // 0x60
    AssetType assetType; // 0x80
}

struct FungibleTransfers {
    uint256 totalProtocolFee;
    uint256 totalSellerTransfer;
    uint256 totalTakerFee;
    uint256 feeRecipientId;
    uint256 makerId;
    address[] feeRecipients;
    address[] makers;
    uint256[] makerTransfers;
    uint256[] feeTransfers;
    AtomicExecution[] executions;
}

struct AtomicExecution { // Size: 0xe0
    uint256 makerId; // 0x00
    uint256 sellerAmount; // 0x20
    uint256 makerFeeRecipientId; // 0x40
    uint256 makerFeeAmount; // 0x60
    uint256 takerFeeAmount; // 0x80
    uint256 protocolFeeAmount; // 0xa0
    StateUpdate stateUpdate; // 0xc0
}

struct StateUpdate { // Size: 0xa0
    address trader; // 0x00
    bytes32 hash; // 0x20
    uint256 index; // 0x40
    uint256 value; // 0x60
    uint256 maxAmount; // 0x80
}

struct Fees { // Size: 0x40
    FeeRate protocolFee; // 0x00
    FeeRate takerFee; // 0x20
}

struct FeeRate { // Size: 0x40
    address recipient; // 0x00
    uint16 rate; // 0x20
}

struct Cancel {
    bytes32 hash;
    uint256 index;
    uint256 amount;
}