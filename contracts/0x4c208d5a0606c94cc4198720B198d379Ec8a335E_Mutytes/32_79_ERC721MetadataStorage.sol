// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

bytes32 constant ERC721_METADATA_STORAGE_SLOT = keccak256("core.token.erc721.metadata.storage");

struct ERC721MetadataStorage {
    string name;
    string symbol;
}

function erc721MetadataStorage() pure returns (ERC721MetadataStorage storage es) {
    bytes32 slot = ERC721_METADATA_STORAGE_SLOT;
    assembly {
        es.slot := slot
    }
}