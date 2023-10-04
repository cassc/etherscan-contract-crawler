// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TeleKeys2 is ERC20 {
    constructor() ERC20(unicode"KEYS 2.0", unicode"TeleKeys 2.0") {
        uint256 tokenSupply = 100000000 * (10**decimals());
        _mint(msg.sender, tokenSupply);
    }
}