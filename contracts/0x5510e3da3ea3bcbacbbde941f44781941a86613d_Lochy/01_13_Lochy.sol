// SPDX-License-Identifier: MIT
// warrencheng.eth
pragma solidity ^0.8.0;
import "./ERC721ATemplate.sol";

contract Lochy is ERC721ATemplate {
    constructor() ERC721ATemplate("Lochy", "TLC", 3333) {
        _safeMint(msg.sender, 1);
    }
}