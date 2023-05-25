// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

/*
    This file contains verbose constant for future use in
    function and inline assembly.
 */

// SaleKind constants.
uint64 constant FIXED_PRICE = 0;
uint64 constant DECREASING_PRICE = 1;
uint64 constant OFFER = 2;
uint64 constant COLLECTION_OFFER = 3;

// AssetTyoe constants.
uint64 constant ASSET_ERC721 = 0;
uint64 constant ASSET_ERC1155 = 1;

// FulfillmentType constants.
uint64 constant STRICT = 0;
uint64 constant PARTIAL = 1;

// PaymentType constants.
uint64 constant ETH_PAYMENT = 0;
uint64 constant ERC20_PAYMENT = 1;

// Constants used for deriving order hash.
uint256 constant TYPEHASH_AND_ORDER_SIZE = 0x1c0;
uint256 constant ORDER_SIZE = 0x180;
uint256 constant COLLECTION_OFFER_SIZE = 0x1a0;
uint256 constant DECREASING_PRICE_ORDER_SIZE = 0x1c0;

// Order offsets, Trade offsets, Auction offsets, Colection offer offsets.
uint256 constant ORDER_NONCE = 0x0;
uint256 constant ORDER_LISTING_TIME = 0x20;
uint256 constant ORDER_EXPIRATION_TIME = 0x40;
uint256 constant ORDER_MAKER = 0x60;
uint256 constant ORDER_TAKER = 0x80;
uint256 constant ORDER_ROYALTY = 0xa0;
uint256 constant ORDER_PAYMENT_TOKEN = 0xc0;
uint256 constant ORDER_BASE_PRICE = 0xe0;
uint256 constant ORDER_TYPE = 0x100;
uint256 constant ORDER_COLLECTION = 0x120;
uint256 constant ORDER_ID = 0x140;
uint256 constant ORDER_AMOUNT = 0x160;
uint256 constant ORDER_RESOLVE_DATA = 0x180;
uint256 constant ORDER_RESOLVE_DATA_LENGTH = 0x1a0;
uint256 constant ORDER_COLECTION_OFFER_ROOTHASH = 0x1c0;
uint256 constant ORDER_COLECTION_OFFER_ROOTHASH_MEMORY = 0x180;
uint256 constant ORDER_PRICE_DECREASE_FLOOR = 0x1c0;
uint256 constant ORDER_DECREASE_FLOOR_MEMORY = 0x180;
uint256 constant ORDER_PRICE_DECREASE_END_TIME = 0x1e0;
uint256 constant ORDER_PRICE_DECREASE_END_TIME_MEMORY = 0x1a0;
uint256 constant TRADE_MAKER = 0;
uint256 constant TRADE_COLLECTION = 0xc0;
uint256 constant TRADE_ID = 0xe0;
uint256 constant TRADE_AMOUNT = 0x100;
uint256 constant TRADE_PAYMENT_TOKEN = 0x60;

// Order status constants.
uint256 constant ORDER_IS_OPEN = 0;
uint256 constant ORDER_IS_PARTIALLY_FILLED = 1;
uint256 constant ORDER_IS_FULFILLED = 2;
uint256 constant ORDER_IS_CANCELLED = 3;

// OrderResult event constants.
bytes32 constant ORDER_RESULT_SELECTOR = 
	0xa6b12b6984bda6bd875df5a33eaeb64d6d12857b59a7d120bf9444b1bf7796a1;
uint256 constant ORDER_RESULT_DATA_LENGTH = 0xaa;
bytes1 constant SUCCESS_CODE = 0xFF;

// Order typehash.
bytes32 constant ORDER_TYPEHASH =
		0x68d866f4b3d9454104b120166fed55c32dec7cdc4364d96d3c35fd74f499a546;

// 
uint256 constant MAX_BULK_ORDER_HEIGHT = 10;

// Typehashes for the merkle tree based on it's height. 
bytes32 constant BULK_ORDER_HEIGHT_ONE_TYPEHASH =
    0xcd0511c3edba288c7b7022a4e9d1309409d7c3dc815549ad502ae3c83153ec8d;

bytes32 constant BULK_ORDER_HEIGHT_TWO_TYPEHASH =
    0x9beb8a38951a872487aa75e49e0e6f218b38eae90fe3657ec10cd87fd1aca5f6;

bytes32 constant BULK_ORDER_HEIGHT_THREE_TYPEHASH =
    0x1907e099cd0b102d6d866a233966dace07bb7555aaaebc8389f11be90fc095c4;

bytes32 constant BULK_ORDER_HEIGHT_FOUR_TYPEHASH =
    0x89ee6c2dd775f15a95d29597ba9ce62100b4dd0bd6b6b2eefcfa4d2bd80af43b;

bytes32 constant BULK_ORDER_HEIGHT_FIVE_TYPEHASH =
    0x21f4c248b5e14bf8fd8d4ce2a90d95af66ada155282e47b9a2fe531c1ac8bf46;

bytes32 constant BULK_ORDER_HEIGHT_SIX_TYPEHASH =
    0x7974a224dd38aa4de830ad422e8b8b87952eb0c7ecdc515455b2d6b93856431f;

bytes32 constant BULK_ORDER_HEIGHT_SEVEN_TYPEHASH =
    0x8786a4d3c6831f1b8000b3fdbe170ebdd58e9ebf3533a5e18b41d7d4a8ef6a2d;

bytes32 constant BULK_ORDER_HEIGHT_EIGHT_TYPEHASH =
    0x525015a897b863903af7bd14d2d1c20bb2b74c85c251887728c8d87a277919d5;

bytes32 constant BULK_ORDER_HEIGHT_NINE_TYPEHASH =
    0x6f0940942471b62e57a516ba875d9e2f380ac3f44782f7a1aa1efd749b236128;

bytes32 constant BULK_ORDER_HEIGHT_TEN_TYPEHASH =
    0x49df94d1aa107700bd757da74f9ff6bd21ae6cedb7b5679fc606558a953e4700;