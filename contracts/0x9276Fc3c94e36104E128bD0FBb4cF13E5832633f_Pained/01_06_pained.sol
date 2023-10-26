// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";

contract Pained is ERC20 {
    constructor() ERC20("Pained", "PAINED") {
        _mint(msg.sender, 1000000 * 10 ** 18);
    }
}