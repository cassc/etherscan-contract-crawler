// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// name: The Hunters 1K
// contract by: buildship.xyz

import "./ERC721Community.sol";

contract HNTRS is ERC721Community {
    constructor() ERC721Community("The Hunters 1K", "HNTRS", 1000, 1, START_FROM_ONE, "ipfs://bafybeihhzz76oijz7kldxy7kgpnu7tkyvcopjcks7l3tfhf4f3ef2rd3fq/",
                                  MintConfig(0 ether, 3, 3, 0, 0x74F96cFbb6C17f02a8AD0342B0fa1D9c2F84f14a, false, false, false)) {}
}