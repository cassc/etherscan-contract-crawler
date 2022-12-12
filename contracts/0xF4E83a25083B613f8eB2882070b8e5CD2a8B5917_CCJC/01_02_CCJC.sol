// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// name: Carnival Caravan by Jcode
// contract by: buildship.xyz

import "./ERC721Community.sol";

contract CCJC is ERC721Community {
    constructor() ERC721Community("Carnival Caravan by Jcode", "CCJC", 250, 1, START_FROM_ONE, "ipfs://bafybeidmjgkgdic5vfxrjwgfysvfym5aoeegzmyehp5mzvb6rkfipuj56u/",
                                  MintConfig(0.0666 ether, 20, 20, 0, 0xa8811a290c1690C39732118331329373693D9e2A, false, false, false)) {}
}