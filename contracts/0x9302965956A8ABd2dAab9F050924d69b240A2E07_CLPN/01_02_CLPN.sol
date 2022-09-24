// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// name: Crypto Lil Pups
// contract by: buildship.xyz

import "./ERC721Community.sol";

contract CLPN is ERC721Community {
    constructor() ERC721Community("Crypto Lil Pups", "CLPN", 11111, 1000, START_FROM_ONE, "ipfs://bafybeihrsuw4fupsw6eqeedyhb34oxyx23afm3phfslfmaptsm35ul2kqq/",
                                  MintConfig(0.04 ether, 10, 20, 0, 0xE92ffd3C3b63A7b05f449748a247b7175AA3d540, false, false, false)) {}
}