// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

bytes32 constant ERC721_BASE_STORAGE_SLOT = keccak256("core.token.erc721.base.storage");

struct ERC721BaseStorage {
    mapping(uint256 => address) owners;
    mapping(address => uint256) inventories;
}

function erc721BaseStorage() pure returns (ERC721BaseStorage storage es) {
    bytes32 slot = ERC721_BASE_STORAGE_SLOT;
    assembly {
        es.slot := slot
    }
}