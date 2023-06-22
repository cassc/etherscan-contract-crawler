// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";

contract ADFund is ERC20 {
    constructor() ERC20("AD Fund", "FUND") {
        _mint(msg.sender, 1500000000 * 10 ** decimals());
    }
}