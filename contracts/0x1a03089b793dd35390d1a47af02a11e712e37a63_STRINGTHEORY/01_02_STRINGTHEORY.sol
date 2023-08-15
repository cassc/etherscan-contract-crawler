// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// name: String Theory
// contract by: artgene.xyz

import "./Artgene721.sol";

contract STRINGTHEORY is Artgene721 {
    constructor() Artgene721("String Theory", "STRINGTHEORY", 0, 1, START_FROM_ONE, "https://metadata.artgene.xyz/api/g/string-theory/",
                              MintConfig(0.006 ether, 10, 10, 0, 0xEC1E36C5b8f4A9797BE676BC1995d959C3bE0fd5, false, 1690473600, 1690560000)) {}
}