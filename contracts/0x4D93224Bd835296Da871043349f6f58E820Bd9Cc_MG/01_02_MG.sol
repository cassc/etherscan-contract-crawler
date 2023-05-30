// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// name: MARS GHOSTs
// contract by: buildship.xyz

import "./ERC721Community.sol";

contract MG is ERC721Community {
    constructor() ERC721Community("MARS GHOSTs", "MG", 3000, 100, START_FROM_ONE, "ipfs://bafybeia6bz5d4ox4izq3wafvlbrakih3xi3ehbd5gmow6l3gyjrw7ispya/",
                                  MintConfig(0.025 ether, 5, 5, 0, 0xd04D13ED110Cc62Df7f9A22FD57C052E57a3ED9A, false, false, false)) {}
}