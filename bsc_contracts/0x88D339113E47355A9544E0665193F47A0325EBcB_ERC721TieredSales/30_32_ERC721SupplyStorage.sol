// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

library ERC721SupplyStorage {
    struct Layout {
        // The next token ID to be minted.
        uint256 currentIndex;
        // The number of tokens burned.
        uint256 burnCounter;
        // Maximum possible supply of tokens.
        uint256 maxSupply;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("v2.flair.contracts.storage.ERC721Supply");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}