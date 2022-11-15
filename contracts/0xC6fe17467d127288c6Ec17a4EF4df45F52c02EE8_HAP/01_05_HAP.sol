// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract HAP is ERC20 {

    constructor() ERC20("WHAT HAPPENED", "HAP") {
        super._mint(msg.sender, 1000000000000000000000000000000000);
    }

}