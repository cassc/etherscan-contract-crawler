// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// name: Rare Y00ts YC
// contract by: buildship.xyz

import "./ERC721Community.sol";

contract RYYC is ERC721Community {
    constructor() ERC721Community("Rare Y00ts YC", "RYYC", 10000, 100, START_FROM_ONE, "ipfs://bafybeiazoznspp3rzrz7ymaxxo5e3m2ihthkovzrp4e23b3azjgrzyqkf4/",
                                  MintConfig(0.0025 ether, 10, 10, 0, 0x39C45e0C037166e16301Ae22e0edd3E6a82025AB, false, false, false)) {}
}