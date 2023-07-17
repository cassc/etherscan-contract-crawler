// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";

contract Fulo is ERC20 {
    constructor() ERC20("Fulo", "FULO") {
        _mint(msg.sender, 24000000 * 10 ** decimals());
    }
}