// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

bytes32 constant ERC721_APPROVABLE_STORAGE_SLOT = keccak256("core.token.erc721.approvable.storage");

struct ERC721ApprovableStorage {
    mapping(uint256 => address) tokenApprovals;
    mapping(address => mapping(address => bool)) operatorApprovals;
}

function erc721ApprovableStorage() pure returns (ERC721ApprovableStorage storage es) {
    bytes32 slot = ERC721_APPROVABLE_STORAGE_SLOT;
    assembly {
        es.slot := slot
    }
}