// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// name: Emoshrooms
// contract by: buildship.xyz

import "./ERC721Community.sol";

contract EMOS is ERC721Community {
    constructor() ERC721Community("Emoshrooms", "EMOS", 5555, 555, START_FROM_ONE, "ipfs://bafybeih3pxbaaaymtygqi6chxn7luhwrho2bbfymjkgpwrw2244i4is67a/",
                                  MintConfig(0.008 ether, 50, 50, 0, 0xE031863DdC3D7D81a7d50c5A14DaA3ca31FAef7b, false, false, false)) {}
}