// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// name: Degen Loot Crate
// contract by: buildship.xyz

import "./ERC721Community.sol";

contract DLC is ERC721Community {
    constructor() ERC721Community("Degen Loot Crate", "DLC", 666, 1, START_FROM_ONE, "ipfs://bafybeigeqxk73oujlyrsgexusokizsnzbad66pnfl222gqlepkubmui25i/",
                                  MintConfig(0.002 ether, 10, 10, 0, 0xA050c0D0C2C88D56cb8aD85b27f2403A2CFfc4f1, false, false, false)) {}
}