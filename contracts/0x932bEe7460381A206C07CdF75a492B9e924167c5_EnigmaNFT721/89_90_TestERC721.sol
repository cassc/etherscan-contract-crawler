// SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.7.6;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract TestERC721 is ERC721 {
    constructor() ERC721("TestERC721", "TEST") {
        _safeMint(msg.sender, 1);
    }
}