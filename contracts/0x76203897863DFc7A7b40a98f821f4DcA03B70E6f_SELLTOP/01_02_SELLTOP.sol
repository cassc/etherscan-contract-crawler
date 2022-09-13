// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// name: Sell This at the Top
// contract by: buildship.xyz

import "./ERC721Community.sol";

contract SELLTOP is ERC721Community {
    constructor() ERC721Community("Sell This at the Top", "SELLTOP", 3999, 500, START_FROM_ZERO, "ipfs://bafybeifmmnye3ge2x23q44ctxx4oykdvqzo5rwfuqcf3xzj3myctbgteba/",
                                  MintConfig(0.005 ether, 3, 0, 0, 0xBd60dF8801C6999b82Bd71d56032e79d8defDcE2, false, false, false)) {}
}