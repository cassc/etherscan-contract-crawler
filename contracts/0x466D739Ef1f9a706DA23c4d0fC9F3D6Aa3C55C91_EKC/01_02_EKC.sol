// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// name: Explorers Kids Club
// contract by: buildship.xyz

import "./ERC721Community.sol";

contract EKC is ERC721Community {
    constructor() ERC721Community("Explorers Kids Club", "EKC", 10000, 20, START_FROM_ONE, "ipfs://bafybeigxceitv4bwhmkaetqlc3wgbk7jymlhwqgy6m56w3wlrno5in7ugy/",
                                  MintConfig(0.02 ether, 3, 3, 0, 0x3786136577d2f5d66e42cffB2bC61799459E055C, false, false, false)) {}
}