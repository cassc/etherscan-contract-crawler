// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";

contract EVERCLEAR is ERC20 {
    constructor() ERC20("EVERCLEAR", "CLEAR") {
        _mint(msg.sender, 15000000000 * 10 ** decimals());
    }
}