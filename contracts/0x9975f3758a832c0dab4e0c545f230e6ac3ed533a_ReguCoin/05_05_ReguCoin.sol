// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/token/ERC20/ERC20.sol";

contract ReguCoin is ERC20 {
    constructor() ERC20("Regulators Coin", "REGU") {
        _mint(msg.sender, 777_000_000_000e18);
    }
}