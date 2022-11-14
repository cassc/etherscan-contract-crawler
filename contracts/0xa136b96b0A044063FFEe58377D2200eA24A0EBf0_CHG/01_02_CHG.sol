// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// name: Crypto Halloween Ghost
// contract by: buildship.xyz

import "./ERC721Community.sol";

contract CHG is ERC721Community {
    constructor() ERC721Community("Crypto Halloween Ghost", "CHG", 10000, 1000, START_FROM_ONE, "ipfs://bafybeih65anrzc4umsnq6alakxaq7imuklucicqnnjrls5gpgsz53cfsbi/",
                                  MintConfig(0.1 ether, 20, 20, 0, 0x981123ca53b980b123d04C88663dAbC225Df6200, false, false, false)) {}
}