// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";

contract SWAPTOKEN is ERC20 {
    constructor() ERC20("SWAPTOKEN", "SWAPTOKEN") {
        _mint(msg.sender, 21000000 * 10 ** decimals());
    }
}