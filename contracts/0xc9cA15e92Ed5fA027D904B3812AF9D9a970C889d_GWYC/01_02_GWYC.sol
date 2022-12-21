// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// name: George Washington Yacht Club
// contract by: buildship.xyz

import "./ERC721Community.sol";

contract GWYC is ERC721Community {
    constructor() ERC721Community("George Washington Yacht Club", "GWYC", 10000, 100, START_FROM_ONE, "ipfs://bafybeid3t4kpm55juguivwv3pmzbuhlqiau373bnal6usykexdxrwoemuy/",
                                  MintConfig(0 ether, 3, 3, 0, 0x173BA8fEcA329a5A0cFbB3067442eE1395883811, false, false, false)) {}
}