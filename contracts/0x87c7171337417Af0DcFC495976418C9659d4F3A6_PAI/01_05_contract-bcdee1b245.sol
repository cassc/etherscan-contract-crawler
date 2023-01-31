// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";

contract PAI is ERC20 {
    constructor() ERC20("PAI", "PORN AI") {
        _mint(msg.sender, 10000 * 10 ** decimals());
    }
}