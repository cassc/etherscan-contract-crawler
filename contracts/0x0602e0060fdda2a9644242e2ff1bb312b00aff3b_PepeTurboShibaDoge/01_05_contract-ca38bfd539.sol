// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";

contract PepeTurboShibaDoge is ERC20 {
    constructor() ERC20("PepeTurboShibaDoge", "PTSD") {
        _mint(msg.sender, 21000000 * 10 ** decimals());
    }
}