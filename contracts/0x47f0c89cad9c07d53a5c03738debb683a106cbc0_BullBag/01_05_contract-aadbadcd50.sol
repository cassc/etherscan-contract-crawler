// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";

contract BullBag is ERC20 {
    constructor() ERC20("Bull Bag", "SACK") {
        _mint(msg.sender, 10000000000 * 10 ** decimals());
    }
}