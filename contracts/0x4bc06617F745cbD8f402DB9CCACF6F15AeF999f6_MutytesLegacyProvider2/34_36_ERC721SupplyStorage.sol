// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

bytes32 constant ERC721_SUPPLY_STORAGE_SLOT = keccak256("core.token.erc721.supply.storage");

struct ERC721SupplyStorage {
    uint256 initialSupply;
    uint256 maxSupply;
    uint256 availableSupply;
}

function erc721SupplyStorage() pure returns (ERC721SupplyStorage storage es) {
    bytes32 slot = ERC721_SUPPLY_STORAGE_SLOT;
    assembly {
        es.slot := slot
    }
}