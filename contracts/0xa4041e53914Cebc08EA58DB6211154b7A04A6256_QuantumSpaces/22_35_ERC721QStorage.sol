// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// // Compiler will pack this into a single 256bit word.
struct TokenOwnership {
    // The address of the owner.
    address addr;
    // Keeps track of the start time of ownership with minimal overhead for tokenomics.
    uint64 startTimestamp;
    // Prevent forward transfer for up to max 256 hours (fraud)
    uint8 freezePeriod;
    // Unused
    uint16 _unused;
    // Whether the token has been burned.
    bool burned;
    bool isPre;
}

// Compiler will pack this into a single 256bit word.
struct AddressData {
    // Realistically, 2**64-1 is more than enough.
    uint64 balance;
    // Keeps track of mint count with minimal overhead for tokenomics.
    uint64 numberMinted;
    // Keeps track of burn count with minimal overhead for tokenomics.
    uint64 numberBurned;
    // For miscellaneous variable(s) pertaining to the address
    // (e.g. number of whitelist mint slots used).
    // If there are multiple variables, please pack them into a uint64.
    uint64 aux;
}

library ERC721QStorage {
    struct Layout {
        // The tokenId of the next token to be minted.
        // Contract should always be offset by 1 everytime a mint starts (for preallocation gas savings)
        mapping(uint128 => uint128) minted;
        // The number of tokens.
        uint256 supplyCounter; //offset by 1 to save gas on mint 0
        // Token name
        string name;
        // Token symbol
        string symbol;
        string baseURI;
        // Mapping from token ID to ownership details
        // An empty struct value does not necessarily mean the token is unowned. See _ownershipOf implementation for details.
        mapping(uint256 => TokenOwnership) ownerships;
        // Mapping owner address to address data
        mapping(address => AddressData) addressData;
        // Mapping from token ID to approved address
        mapping(uint256 => address) tokenApprovals;
        // Mapping from owner to operator approvals
        mapping(address => mapping(address => bool)) operatorApprovals;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("quantum.contracts.storage.erc721q.v1");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}
//ERC721QStorage.Layout storage erc = ERC721QStorage.layout();