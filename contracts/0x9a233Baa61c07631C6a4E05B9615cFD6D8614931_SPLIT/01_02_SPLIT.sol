// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// name: Split Example
// contract by: buildship.xyz

import "./ERC721Community.sol";

contract SPLIT is ERC721Community {
    constructor() ERC721Community("Split Example", "SPLIT", 1000, 1, START_FROM_ONE, "ipfs://bafybeigzkglkoj3i4cdxxv3ce5rb4d5nqagwqteqzmzdmw52l4fy6i2jie/",
                                  MintConfig(0.001 ether, 3, 3, 0, 0x5A5843B8469D4CF113d0d4f4cE30241d73C13A80, true, false, false)) {}
}