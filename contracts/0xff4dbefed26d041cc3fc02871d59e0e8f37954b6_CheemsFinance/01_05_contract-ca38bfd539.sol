// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract CheemsFinance is ERC20 {
    constructor() ERC20("Cheems Finance", "Cheems Finance") {
        _mint(msg.sender, 1000000 * 10 ** decimals());
    }
}