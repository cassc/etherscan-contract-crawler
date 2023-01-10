// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

library ManagementStorage {
    bytes32 internal constant STORAGE_SLOT = keccak256("untrading.unDiamond.NFT.facet.management.storage");

    struct Layout {
        address untradingManager;
        uint256 managerCut; // This is the cut of the oTokens that the untradingManager gets
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}