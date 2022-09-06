// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

bytes32 constant ERC721_TOKEN_URI_STORAGE_SLOT = keccak256("core.token.erc721.tokenURI.storage");

struct ProviderInfo {
    bool isProxyable;
    address providerAddress;
}

struct ERC721TokenURIStorage {
    uint256 defaultProvider;
    mapping(uint256 => uint256) tokenURIProviders;
    mapping(uint256 => ProviderInfo) providerInfo;
}

function erc721TokenURIStorage() pure returns (ERC721TokenURIStorage storage es) {
    bytes32 slot = ERC721_TOKEN_URI_STORAGE_SLOT;
    assembly {
        es.slot := slot
    }
}