// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// name: Nixpradus
// contract by: buildship.xyz

import "./ERC721Community.sol";

contract NXPDS is ERC721Community {
    constructor() ERC721Community("Nixpradus", "NIX", 3000, 300, START_FROM_ONE, "ipfs://bafybeigj7vsmpvvawhleeeoxcqfr4vozuhtswee7kto3sfivfsatiq5j4u/",
                                  MintConfig(0.003 ether, 3, 4, 0, 0xb39cfA7BaF9DfAb15db62746BF617Ab816384CC0, false, false, false)) {}
}