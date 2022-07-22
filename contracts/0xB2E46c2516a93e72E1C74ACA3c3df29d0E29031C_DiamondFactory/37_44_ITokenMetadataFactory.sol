//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../libraries/UInt256Set.sol";

// represents a set of values and quantities for a metadata type. 
struct MetadataTypeDefinition {
    string typeName;
    string[] values; // encodes the string[] of values for the fields listed in the fields array
    uint256[] quantities;
}

struct MetadataDefinition {
    string typeName;
    string value;
}

enum MetadataDerivationMode {
    PREASSIGNED,
    PROBABILISTIC
}

struct TokenMetadataFactoryContract {
    mapping(string => mapping(string => uint256)) metadataTypeToValueToQuantity;
    mapping(string => string[]) metadataTypeToValues;
    string[] metadataTypes;
    uint256[][] preassignedMetadataValues;
    uint256 preassignedMetadataValueCount;
    string[] preassignedMetadataKeys;
    mapping(string => bool) metadataTypeExists;
    MetadataDerivationMode derivationMode;
}

struct MetadataValues {
    string[] values;
    uint256[] valueIndices; // keep an array of the value indices for imageUrl
}