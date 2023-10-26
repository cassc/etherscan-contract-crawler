// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";

contract EndTheFed is ERC20 {
    constructor() ERC20("EndTheFed", "END") {
        _mint(msg.sender, 10000000000 * 10 ** 18);
    }
}