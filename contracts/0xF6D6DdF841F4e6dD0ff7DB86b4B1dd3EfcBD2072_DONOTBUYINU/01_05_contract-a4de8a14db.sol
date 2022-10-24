// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";

contract DONOTBUYINU is ERC20 {
    constructor() ERC20("DO NOT BUY INU", "DNBINU") {
        _mint(msg.sender, 1000000000 * 10 ** decimals());
    }
}