// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";

contract BROTHER is ERC20 {
    constructor() ERC20("BROTHER", "BROTHER") {
        _mint(msg.sender, 725696969 * 10 ** decimals());
    }
}