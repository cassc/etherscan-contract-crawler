// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// name: Metrotopiaclub
// contract by: buildship.xyz

import "./ERC721Community.sol";

contract Hisoka is ERC721Community {
    constructor() ERC721Community("Metrotopiaclub", "Hisoka", 1000, 5, START_FROM_ONE, "ipfs://bafybeihdjjzub3fagxlwyebwaxk2rowcro3nvfzso2bkrf3z3cmsweefoe/",
                                  MintConfig(0.02 ether, 7, 7, 0, 0x9fcBD15b5EFd1bf7a617FC9B92a33b07C327784a, false, false, false)) {}
}