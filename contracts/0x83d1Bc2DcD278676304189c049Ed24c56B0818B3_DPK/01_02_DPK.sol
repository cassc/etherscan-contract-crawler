// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// name: Dream Poker Club
// contract by: buildship.xyz

import "./ERC721Community.sol";

contract DPK is ERC721Community {
    constructor() ERC721Community("Dream Poker Club", "DPK", 10000, 1000, START_FROM_ONE, "ipfs://bafybeifsqamxtdlwmbpynbvsned7vx7qrs7fzgim4mcddpn7vt7c6uxjmq/",
                                  MintConfig(0.0065 ether, 50, 50, 0, 0x17F2A54735407a82e3f8A0ed369842733a9381e0, false, false, false)) {}
}