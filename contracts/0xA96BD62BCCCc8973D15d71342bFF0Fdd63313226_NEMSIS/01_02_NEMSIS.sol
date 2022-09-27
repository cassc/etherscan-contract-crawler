// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// name: NEMSIS Token
// contract by: buildship.xyz

import "./ERC721Community.sol";

contract NEMSIS is ERC721Community {
    constructor() ERC721Community("NEMSIS Token", "NEMSIS", 555, 1, START_FROM_ONE, "ipfs://bafybeifrtgyhef55gc3ecvnl3wtkautksm4b2ozjqm2y3cpwtbepoaxi3q/",
                                  MintConfig(0.01 ether, 2, 2, 0, 0x1a9F45b1743864BF2AD26a32F7c4c71B2aD6EB06, false, false, false)) {}
}