// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";

contract MuskSinkInu is ERC20 {
    constructor() ERC20("Musk Sink Inu", "SINK") {
        _mint(msg.sender, 100000000 * 10 ** decimals());
    }
}