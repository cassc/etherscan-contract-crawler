// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/* solhint-disable indent */

// Compiler will pack this into a single 256bit word.
struct TokenOwnership {
    address addr; // The address of the owner.
    uint64 startTimestamp; // Keeps track of the start time of ownership with minimal overhead for tokenomics.
    bool burned; // Whether the token has been burned.
}

// Compiler will pack this into a single 256bit word.
struct AddressData {
    
    uint64 balance; // Realistically, 2**64-1 is more than enough.
    uint64 numberMinted; // Keeps track of mint count with minimal overhead for tokenomics.
    uint64 numberBurned; // Keeps track of burn count with minimal overhead for tokenomics.
    // For miscellaneous variable(s) pertaining to the address
    // (e.g. number of whitelist mint slots used).
    // If there are multiple variables, please pack them into a uint64.
    uint64 aux;
}

struct ERC721AContract {
    // The tokenId of the next token to be minted.
    uint256 _currentIndex;

    // The number of tokens burned.
    uint256 _burnCounter;

    // Token name
    string _name;

    // Token symbol
    string _symbol;

    // the base uri
    string __uri;

    // Mapping from token ID to ownership details
    // An empty struct value does not necessarily mean the token is unowned. See ownershipOf implementation for details.
    mapping(uint256 => TokenOwnership) _ownerships;

    // Mapping owner address to address data
    mapping(address => AddressData) _addressData;

    // Mapping from token ID to approved address
    mapping(uint256 => address) _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) _operatorApprovals;
}