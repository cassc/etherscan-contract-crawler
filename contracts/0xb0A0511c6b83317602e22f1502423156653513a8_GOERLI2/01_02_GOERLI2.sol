// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// name: Goerli Second
// contract by: buildship.xyz

import "./ERC721Community.sol";

contract GOERLI2 is ERC721Community {
    constructor() ERC721Community("Goerli Second", "GOERLI2", 1000, 1, START_FROM_ONE, "ipfs://bafybeieq7doojjyi7awyu3qmryzx3kbmscqnrpvkxar23fzthjqa6ebity/",
                                  MintConfig(0.01 ether, 3, 3, 0, 0x297588a9487B12E6AB58e549f58681790ee674e4, false, false, false)) {}
}