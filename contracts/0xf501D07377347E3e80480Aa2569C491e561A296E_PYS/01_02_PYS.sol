// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// name: PuffySouls
// contract by: buildship.xyz

import "./ERC721Community.sol";

contract PYS is ERC721Community {
    constructor() ERC721Community("PuffySouls", "PYS", 4444, 1, START_FROM_ONE, "ipfs://bafybeidzw2mi7kwi76ap7szywgzmqvl47sog6jvmhms5avamscoxuc466e/",
                                  MintConfig(0.002 ether, 3, 3, 0, 0xE1d73108B20477d4A9d84D8D15491aa90B016174, false, false, false)) {}
}