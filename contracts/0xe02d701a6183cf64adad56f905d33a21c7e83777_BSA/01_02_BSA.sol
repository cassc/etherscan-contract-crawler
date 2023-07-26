// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// name: The Bonsai Assemblance
// contract by: buildship.xyz

import "./ERC721Community.sol";

contract BSA is ERC721Community {
    constructor() ERC721Community("The Bonsai Assemblance", "BSA", 333, 10, START_FROM_ONE, "ipfs://bafybeiaxku73hymvw7qtflno3wflfiiif4xc6srhl34mony6ddjpjci26q/",
                                  MintConfig(0.1 ether, 1, 1, 0, 0x3257A781C7682f9b77347A3105ac11Fe0B49b853, false, false, false)) {}
}