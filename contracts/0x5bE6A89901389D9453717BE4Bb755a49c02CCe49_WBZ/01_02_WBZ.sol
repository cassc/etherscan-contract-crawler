// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// name: WeBearz
// contract by: buildship.xyz

import "./ERC721Community.sol";

contract WBZ is ERC721Community {
    constructor() ERC721Community("WeBearz", "WBZ", 5500, 5, START_FROM_ONE, "ipfs://bafybeig5cfg4entvg3pvouq45wbi2lnnm75jv5a5gza6y2vqyzdp4hvlcq/",
                                  MintConfig(0 ether, 1, 1, 0, 0xD8D9a80F831F7F1055A3548Db2f7142082e32C8d, false, false, false)) {}
}