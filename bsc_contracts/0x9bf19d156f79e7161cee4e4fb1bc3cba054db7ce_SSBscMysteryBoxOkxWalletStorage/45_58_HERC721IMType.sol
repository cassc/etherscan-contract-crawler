// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library HERC721IMType {

    struct constructParam {
        string name;
        string symbol;
        string baseURI;
        bool supportTransfer;
        bool supportMint;
        bool supportBurn;
    }

    struct AttributeRegistry {
        bytes32 attributeName;
        uint256 attributeType;
    }

    uint256 constant ATTRIBUTE_TYPE_UNKNOWN = 0;
    uint256 constant ATTRIBUTE_TYPE_UINT256 = 1;
    uint256 constant ATTRIBUTE_TYPE_BYTES32 = 2;
    uint256 constant ATTRIBUTE_TYPE_ADDRESS = 3;
    uint256 constant ATTRIBUTE_TYPE_BYTES = 4;
}