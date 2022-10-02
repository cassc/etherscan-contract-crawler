// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// name: Casual Bears
// contract by: buildship.xyz

import "./ERC721Community.sol";

contract Bears is ERC721Community {
    constructor() ERC721Community("Casual Bears", "Bears", 999, 1, START_FROM_ONE, "ipfs://bafybeiaaj6o4jd7exar4gt2u6tt5whlir55vgy6rafuvmku7o5gt2bw45q/",
                                  MintConfig(0.02 ether, 5, 20, 0, 0xf642F08Da6C45aDDbf8fC11e5e5c86BCbaa87BEA, false, false, false)) {}
}