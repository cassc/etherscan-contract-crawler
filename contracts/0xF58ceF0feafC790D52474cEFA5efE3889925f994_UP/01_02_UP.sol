// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// name: UggoPepe by Peekasso
// contract by: buildship.xyz

import "./ERC721Community.sol";

contract UP is ERC721Community {
    constructor() ERC721Community("UggoPepe by Peekasso", "UP", 555, 1, START_FROM_ONE, "ipfs://bafybeietnh5jjevdog32xgwse37wgjsnzvdgxixg4em64bubdladzbxymu/",
                                  MintConfig(0.002 ether, 10, 20, 0, 0x230eA653163164c78d04094A796faa43D9616446, false, false, false)) {}
}