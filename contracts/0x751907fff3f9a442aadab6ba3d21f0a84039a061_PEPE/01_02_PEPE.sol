// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// name: Pepe Elementals

import "./ERC721Community.sol";

contract PEPE is ERC721Community {
    constructor() ERC721Community("Pepe Elementals", "PEPE", 999, 20, START_FROM_ONE, "ipfs://bafybeifewjqruyknahaj4ns2ebty3azfmkudcmcxbmm7qc24go37buv4yu/",
                                  MintConfig(0.0005 ether, 3, 3, 0, 0x1731f6d8987771a9006EC51960B8c1BcfE1F1E24, false, false, false)) {}
}