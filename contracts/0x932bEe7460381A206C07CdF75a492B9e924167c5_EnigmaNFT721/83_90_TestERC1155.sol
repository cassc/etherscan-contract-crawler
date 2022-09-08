// SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.7.6;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract TestERC1155 is ERC1155 {
    constructor() ERC1155("https://testERC1155/") {
        _mint(msg.sender, 1, 10, "");
    }
}