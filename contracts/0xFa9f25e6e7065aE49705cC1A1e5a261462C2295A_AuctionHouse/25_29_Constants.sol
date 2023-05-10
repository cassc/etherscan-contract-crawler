// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/*

NOTE ON SEPOLIA:

The address 0x000000000000AAeB6D7670E522A718067333cd4E is currently broken on Sepolia,
pending OpenSea sepolia support.

A temporary workaround to get the WildNFT deploying on sepolia is to use a non-existing
address such as 0xB69c34f580d74396Daeb327D35B4fb4677353Fa9

For production, please change this to the correct address.

*/
address constant CANONICAL_OPERATOR_FILTER_REGISTRY_ADDRESS = 0xB69c34f580d74396Daeb327D35B4fb4677353Fa9;//0x000000000000AAeB6D7670E522A718067333cd4E;
address constant CANONICAL_CORI_SUBSCRIPTION = 0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6;