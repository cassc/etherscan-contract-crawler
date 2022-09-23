// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// name: ensgamingeth
// contract by: buildship.xyz

import "./ERC721Community.sol";

contract ensgaming is ERC721Community {
    constructor() ERC721Community("ensgamingeth", "ensgaming", 5000, 20, START_FROM_ONE, "ipfs://bafybeifxbmp6m3xeoggzmkbigwryxfazdvxtrjlwckmka6wiarm4soujxe/",
                                  MintConfig(0.012 ether, 4, 4, 0, 0xc85d67B3401E42Ac234b511317e859dB5aB29197, false, false, false)) {}
}