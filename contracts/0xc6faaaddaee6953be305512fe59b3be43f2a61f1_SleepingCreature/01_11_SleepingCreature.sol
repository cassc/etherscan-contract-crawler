// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
//By: @phatstraws
contract SleepingCreature is ERC1155Supply, Ownable  {
    uint constant TOKEN_ID = 0;
    uint constant MAX_TOKENS = 250;

    constructor(string memory uri) ERC1155(uri) {
    }

    function forceMint(address to, uint amount) public onlyOwner {
       _mint(to, TOKEN_ID, amount, "");
    }

    function reserve(address[] calldata addresses) public onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
       _mint(addresses[i], TOKEN_ID, 1, "");
    }
  }
    
}