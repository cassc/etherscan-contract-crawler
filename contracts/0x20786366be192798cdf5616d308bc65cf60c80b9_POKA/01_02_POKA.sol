// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// name: Poka House
// contract by: buildship.xyz

import "./ERC721Community.sol";

contract POKA is ERC721Community {
    constructor() ERC721Community("Poka House", "POKA", 1000, 500, START_FROM_ONE, "ipfs://bafybeiairwe5bgrwtkvvzbr2yw5slkmq3wuf2zsqm62rpbvjjo3pqzxtqe/",
                                  MintConfig(0.001 ether, 50, 50, 0, 0x81d2389ff797ac86ab860028d79911c817E8b89f, false, false, false)) {}
}