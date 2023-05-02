// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";

contract LETSGOBRANDON is ERC20 {
    constructor() ERC20("LETSGOBRANDON", "LGB") {
        _mint(msg.sender, 1000000000000000000000 * 10 ** decimals());
    }
}