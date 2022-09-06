// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

bytes32 constant ERC721_ENUMERABLE_STORAGE_SLOT = keccak256("core.token.erc721.enumerable.storage");

struct PageInfo {
    uint16 length;
    address pageAddress;
}

struct ERC721EnumerableStorage {
    PageInfo[] pages;
}

function erc721EnumerableStorage() pure returns (ERC721EnumerableStorage storage es) {
    bytes32 slot = ERC721_ENUMERABLE_STORAGE_SLOT;
    assembly {
        es.slot := slot
    }
}