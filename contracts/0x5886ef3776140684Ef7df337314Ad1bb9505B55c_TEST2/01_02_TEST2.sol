// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// name: Payouts Test 2
// contract by: buildship.xyz

import "./ERC721Community.sol";

contract TEST2 is ERC721Community {
    constructor() ERC721Community("Payouts Test 2", "TEST2", 1000, 1, START_FROM_ONE, "ipfs://bafybeidsekw37osxx6i3chg7m7lfkzwcwebyfu3cdqkc6dkdie3w4lznfu/",
                                  MintConfig(0.001 ether, 3, 3, 0, 0xc5b9ad0F5B64190E5476015EEb1724F5676bd51F, true, false, false)) {}
}