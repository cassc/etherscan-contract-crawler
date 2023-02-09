// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.9;

/// @title Errors library
library Errors {
    string public constant INVALID_TOKEN_AMOUNT = "1"; // Input token amount must be greater than 0
    string public constant INVALID_TOKEN_ADDRESS = "2"; // Input token address is zero
    string public constant INVALID_TOKEN_ARRAY_LENGTH = "3"; // Invalid tokenAddresses array length. 0 < length <= 100. Max 100 elements
    string public constant INVALID_AMOUNT_ARRAY_LENGTH = "4"; // Invalid tokenAmounts array length. 0 < length <= 100. Max 100 elements
    string public constant INVALID_IDS_ARRAY_LENGTH = "5"; // Invalid tokenIds array length. 0 < length <= 100. Max 100 elements
    string public constant LENGTH_MISMATCH = "6"; // Array length must be same
    string public constant NOT_NFT_OWNER = "7"; // Caller/Minter is not NFT owner
    string public constant NOT_CAPSULE = "8"; // Provided address or caller is not a valid Capsule address
    string public constant NOT_MINTER = "9"; // Provided address or caller is not Capsule minter
    string public constant NOT_COLLECTION_MINTER = "10"; // Provided address or caller is not collection minter
    string public constant ZERO_ADDRESS = "11"; // Input/provided address is zero.
    string public constant NON_ZERO_ADDRESS = "12"; // Address under check must be 0
    string public constant SAME_AS_EXISTING = "13"; // Provided address/value is same as stored in state
    string public constant NOT_SIMPLE_CAPSULE = "14"; // Provided Capsule id is not simple Capsule
    string public constant NOT_ERC20_CAPSULE_ID = "15"; // Provided token id is not the id of single/multi ERC20 Capsule
    string public constant NOT_ERC721_CAPSULE_ID = "16"; // Provided token id is not the id of single/multi ERC721 Capsule
    string public constant ADDRESS_DOES_NOT_EXIST = "17"; // Provided address does not exist in valid address list
    string public constant ADDRESS_ALREADY_EXIST = "18"; // Provided address does exist in valid address lists
    string public constant INCORRECT_TAX_AMOUNT = "19"; // Tax amount is incorrect
    string public constant UNAUTHORIZED = "20"; // Caller is not authorized to perform this task
    string public constant BLACKLISTED = "21"; // Caller is blacklisted and can not interact with Capsule protocol
    string public constant WHITELISTED = "22"; // Caller is whitelisted
    string public constant NOT_TOKEN_URI_OWNER = "23"; // Provided address or caller is not tokenUri owner
    string public constant NOT_ERC1155_CAPSULE_ID = "24"; // Provided token id is not the id of single/multi ERC1155 Capsule
    string public constant NOT_WHITELISTED_CALLERS = "25"; // Caller is not whitelisted
    string public constant NOT_COLLECTION_BURNER = "26"; // Caller is not collection burner
    string public constant NOT_PRIVATE_COLLECTION = "27"; // Provided address is not private Capsule collection
}