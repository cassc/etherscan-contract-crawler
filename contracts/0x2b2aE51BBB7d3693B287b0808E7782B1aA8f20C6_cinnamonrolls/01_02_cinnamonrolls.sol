// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// name: cinnamonrollseth
// contract by: buildship.xyz

import "./ERC721Community.sol";

contract cinnamonrolls is ERC721Community {
    constructor() ERC721Community("cinnamonrollseth", "cinnamonrolls", 750, 20, START_FROM_ONE, "ipfs://bafybeiawxk2wkpcjkpwkpabypaolkzw2eoquakjkgke55p3xwfc7u6huua/",
                                  MintConfig(0.009 ether, 4, 4, 0, 0x85F422562d4105ECbcC6b0345D890c8979519419, false, false, false)) {}
}