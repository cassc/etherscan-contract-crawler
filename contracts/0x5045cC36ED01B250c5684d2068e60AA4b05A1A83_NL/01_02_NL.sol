// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// name: De Nederlanders
// contract by: buildship.xyz

import "./ERC721Community.sol";

//////////////
//          //
//          //
//    NL    //
//          //
//          //
//////////////

contract NL is ERC721Community {
    constructor() ERC721Community("De Nederlanders", "NL", 10000, 1000, START_FROM_ONE, "ipfs://bafybeielt436octycwwc6lm7icgiaszelcvkwevoysvuzeicqjwvzkqouu/",
                                  MintConfig(0.012 ether, 10, 10, 0, 0xbA20bf0b56A6f58d26A702AA0a8c40A5f30E238b, false, false, false)) {}
}