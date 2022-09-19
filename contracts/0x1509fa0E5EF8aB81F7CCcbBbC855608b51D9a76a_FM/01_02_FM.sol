// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// name: Machinery
// contract by: buildship.xyz

import "./ERC721Community.sol";

contract FM is ERC721Community {
    constructor() ERC721Community("Machinery", "FM", 115, 15, START_FROM_ONE, "ipfs://bafybeidhcwz3e3kxe6kbm4pct3rife6rlryrepbi4dxmd5frujrg5lneya/",
                                  MintConfig(0.05 ether, 1, 1, 0, 0xeaAa20ec969724Fb35AB9c998A94A567A2388282, false, false, false)) {}
}