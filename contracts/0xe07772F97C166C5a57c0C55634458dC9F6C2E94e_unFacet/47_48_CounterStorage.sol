// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

library CounterStorage {
    bytes32 internal constant STORAGE_SLOT = keccak256("untrading.unDiamond.NFT.facet.counter.storage");

    struct Layout {
        uint256 tokenIds;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    function currentTokenId() internal view returns (uint256) {
        return layout().tokenIds;
    }

    function incrementTokenId() internal {
        layout().tokenIds += 1;
    }
}