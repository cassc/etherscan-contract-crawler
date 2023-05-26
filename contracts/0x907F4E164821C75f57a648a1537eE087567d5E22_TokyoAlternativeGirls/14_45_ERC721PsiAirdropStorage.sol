// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "solidity-bits/contracts/BitMaps.sol";

library ERC721PsiAirdropStorage {
    using BitMaps for BitMaps.BitMap;

    struct Layout {
        // The start token Id airdropped.
        uint32 startAirdropIndex;
        // Address length in pointer. Only last pointer is allowed it is less than this legnth.
        uint16 addressLengthInPointer;
        // Next unairdroped index of airdrop list pointers. Manipulating pointers is irreversible.
        uint16 nextPointerIndex;
        // Pointers of the list of address list contract. Each contract should have the address list for airdrop.
        // The Format of the list follows ImmutableArray. 
        address[] airdropListPointers;
        // A flag indicating that the token ID has already been transferred after airdrop.
        BitMaps.BitMap transferred;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256('ERC721PsiAirdrop.contracts.storage.facet');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}