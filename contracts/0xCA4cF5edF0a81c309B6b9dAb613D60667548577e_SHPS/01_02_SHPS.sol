// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// name: Shapes
// contract by: buildship.xyz

import "./ERC721Community.sol";

contract SHPS is ERC721Community {
    constructor() ERC721Community("Shapes", "SHPS", 444, 4, START_FROM_ONE, "ipfs://bafybeiaewj3rzsf4x224sse33dpprf72qbfaohbwl6kopdwm56vjvq7b4m/",
                                  MintConfig(0.1 ether, 10, 10, 0, 0xEedEC90b72E259c6dEDC8A37Fe4e73B85571f7F7, false, false, false)) {}
}