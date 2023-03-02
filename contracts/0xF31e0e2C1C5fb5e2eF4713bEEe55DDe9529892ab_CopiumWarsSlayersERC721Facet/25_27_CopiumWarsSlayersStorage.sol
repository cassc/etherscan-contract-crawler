// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

library CopiumWarsSlayersStorage {
    struct Layout {
        address payable copiumBank;
        address theExecutor;
        uint256 startTime;
        string baseURI;
        string contractURI;
        mapping(uint256 => bool) usedMintTokens;
        mapping(address => uint256) lockedBalance;
        // IMPORTANT: For update append only, do not re-order fields!
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("copium.wars.storage.slayers");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}