// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";

contract CallOfChampions is ERC20 {
    constructor() ERC20("Call of Champions", "COC") {
        _mint(msg.sender, 123000000000 * 10 ** decimals());
    }
}