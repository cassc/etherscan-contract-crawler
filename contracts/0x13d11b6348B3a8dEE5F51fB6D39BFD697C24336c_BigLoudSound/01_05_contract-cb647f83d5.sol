// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";

contract BigLoudSound is ERC20 {
    constructor() ERC20("Big Loud Sound", "BLS") {
        _mint(msg.sender, 123000000000 * 10 ** decimals());
    }
}