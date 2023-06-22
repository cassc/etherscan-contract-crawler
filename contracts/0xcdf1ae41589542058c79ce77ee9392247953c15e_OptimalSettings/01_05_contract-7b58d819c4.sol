// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";

contract OptimalSettings is ERC20 {
    constructor() ERC20("Optimal Settings", "BEST") {
        _mint(msg.sender, 150000000000 * 10 ** decimals());
    }
}