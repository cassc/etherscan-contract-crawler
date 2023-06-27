// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// name: Poka Fighters
// contract by: buildship.xyz

import "./ERC721Community.sol";

contract POKA is ERC721Community {
    constructor() ERC721Community("Poka Fighters", "POKA", 1000, 1, START_FROM_ONE, "ipfs://bafybeidlnzuljumyyratibr2csfleqg2xeiat7utujiyno6zxuutxy52je/",
                                  MintConfig(0.001 ether, 20, 20, 0, 0x81d2389ff797ac86ab860028d79911c817E8b89f, false, false, false)) {}
}