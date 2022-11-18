// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// name: Cute Frog Club
// contract by: buildship.xyz

import "./ERC721Community.sol";

contract CUTEFRG is ERC721Community {
    constructor() ERC721Community("Cute Frog Club", "CUTEFRG", 2222, 222, START_FROM_ONE, "ipfs://bafybeia6za6he3vprjezzkxggaicmjlqgu6xsil5lyiuq64usg5lowzjgy/",
                                  MintConfig(0.003 ether, 10, 0, 0, 0x1090F527d7E82ef39713699f626F569CA660185C, false, false, false)) {}
}