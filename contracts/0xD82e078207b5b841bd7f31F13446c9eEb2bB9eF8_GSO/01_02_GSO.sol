// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// name: GASSHO V2
// contract by: buildship.xyz

import "./ERC721Community.sol";

contract GSO is ERC721Community {
    constructor() ERC721Community("GASSHO V2", "GSO", 10000, 100, START_FROM_ONE, "ipfs://bafybeihhnpkdh2iblzidefe54qv2qk4wif67gmjxdeygwoijn7zyxy234m/",
                                  MintConfig(0 ether, 50, 50, 0, 0x26B08544Ae7abf3E84741c66877aCDa8F4Ec712f, false, false, false)) {}
}