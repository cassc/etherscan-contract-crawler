// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// name: TruBelieversOG
// contract by: buildship.xyz

import "./ERC721Community.sol";

contract TBOG is ERC721Community {
    constructor() ERC721Community("TruBelieversOG", "TBOG", 9876, 207, START_FROM_ZERO, "ipfs://bafybeigvuq6ubrqgp6lujgsmvfingav2kiv7m5bm4gbxa3b7ym7vg7hnxe/",
                                  MintConfig(0.013 ether, 9, 0, 0, 0x8b0b82C0c2C670cf6535b9E232D7CF6eAFaD434C, false, false, false)) {}
}