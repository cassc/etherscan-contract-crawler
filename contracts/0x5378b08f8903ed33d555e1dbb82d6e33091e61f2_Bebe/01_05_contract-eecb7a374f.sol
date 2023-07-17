// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";

contract Bebe is ERC20 {
    constructor() ERC20("Bebe", "BEBE") {
        _mint(msg.sender, 24000000 * 10 ** decimals());
    }
}