// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/// @dev Name of the NounletToken contract
string constant NAME = "NounletToken";

/// @dev Version number of the NounletToken contract
string constant VERSION = "1";

/// @dev The EIP-712 typehash for the contract's domain
bytes32 constant DOMAIN_TYPEHASH = keccak256(
    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
);

/// @dev The EIP-712 typehash for the permit struct used by the contract
bytes32 constant PERMIT_TYPEHASH = keccak256(
    "Permit(address owner,address operator,uint256 tokenId,bool approved,uint256 nonce,uint256 deadline)"
);

/// @dev The EIP-712 typehash for the permit all struct used by the contract
bytes32 constant PERMIT_ALL_TYPEHASH = keccak256(
    "PermitAll(address owner,address operator,bool approved,uint256 nonce,uint256 deadline)"
);